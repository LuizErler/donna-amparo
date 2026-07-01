import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../domain/medication/entities/medication_doses_result.dart';
import '../../../domain/medication/entities/medication_schedule_mode.dart';
import '../../../domain/medication/entities/medication_skipped_reason.dart';
import '../../../domain/medication/entities/medication_summary.dart';
import '../../../domain/medication/services/medication_dose_generator.dart';

class MedicationRemoteDataSource {
  SupabaseClient get _client => supabase;

  static const _medicationSelect = '''
    id,
    name,
    dosage,
    instructions,
    is_active,
    start_date,
    end_date,
    schedule_mode,
    interval_hours,
    anchor_time,
    medication_schedules (
      id,
      time_of_day
    )
  ''';

  Future<MedicationDosesResult> listDoses({
    required String patientId,
    required DateTime day,
    bool includeOverdue = true,
  }) async {
    final today = _dateOnly(day);
    final lookback = includeOverdue
        ? today.subtract(
            const Duration(days: MedicationDoseGenerator.overdueLookbackDays),
          )
        : today;

    final rows = await _client
        .from('medications')
        .select(_medicationSelect)
        .eq('patient_id', patientId)
        .eq('is_active', true)
        .order('name', ascending: true);

    final logs = await _client
        .from('medication_logs')
        .select(
            'id, medication_id, scheduled_for, scheduled_time, taken, skipped_reason')
        .eq('patient_id', patientId)
        .gte('scheduled_for', _formatDate(lookback))
        .lte('scheduled_for', _formatDate(today));

    final logsByKey = <String, Map<String, dynamic>>{};
    for (final raw in logs as List<dynamic>) {
      final row = raw as Map<String, dynamic>;
      final key =
          '${row['medication_id']}:${row['scheduled_for']}:${row['scheduled_time']}';
      logsByKey[key] = row;
    }

    return MedicationDoseGenerator.buildResult(
      medications: (rows as List<dynamic>).cast<Map<String, dynamic>>(),
      logsByKey: logsByKey,
      today: today,
      includeOverdue: includeOverdue,
    );
  }

  Future<List<MedicationSummary>> listMedications({
    required String patientId,
    bool activeOnly = false,
  }) async {
    var query = _client
        .from('medications')
        .select(_medicationSelect)
        .eq('patient_id', patientId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final rows = await query.order('name', ascending: true);
    return (rows as List<dynamic>)
        .map((r) => MedicationSummary.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> setDoseTaken({
    required String patientId,
    required int medicationId,
    required int? scheduleId,
    required String scheduledTime,
    required DateTime day,
    required bool taken,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Usuario nao autenticado.');
    }

    final dayStr = _formatDate(day);

    if (taken) {
      final payload = <String, dynamic>{
        'medication_id': medicationId,
        'patient_id': patientId,
        'scheduled_for': dayStr,
        'scheduled_time': scheduledTime,
        'taken': true,
        'taken_at': DateTime.now().toUtc().toIso8601String(),
        'taken_by': userId,
      };
      if (scheduleId != null && scheduleId > 0) {
        payload['schedule_id'] = scheduleId;
      }
      await _client.from('medication_logs').upsert(
        payload,
        onConflict: 'medication_id,scheduled_for,scheduled_time',
      );
      return;
    }

    await _client
        .from('medication_logs')
        .delete()
        .eq('medication_id', medicationId)
        .eq('scheduled_for', dayStr)
        .eq('scheduled_time', scheduledTime)
        .catchError((Object error) {
      throw _mapError(error, 'Erro ao desfazer confirmacao da dose.');
    });
  }

  Future<void> createMedication({
    required String patientId,
    required String name,
    String? dosage,
    String? instructions,
    required List<String> scheduleTimes,
    required DateTime startDate,
    DateTime? endDate,
    required MedicationScheduleMode scheduleMode,
    int? intervalHours,
    String? anchorTime,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Usuario nao autenticado.');
    }

    final medRow = await _client
        .from('medications')
        .insert(_medicationPayload(
          patientId: patientId,
          name: name,
          dosage: dosage,
          instructions: instructions,
          startDate: startDate,
          endDate: endDate,
          scheduleMode: scheduleMode,
          intervalHours: intervalHours,
          anchorTime: anchorTime,
          createdBy: userId,
        ))
        .select('id')
        .single()
        .catchError((Object error) {
      throw _mapError(error, 'Erro ao cadastrar medicamento.');
    });

    if (scheduleMode == MedicationScheduleMode.fixedTimes) {
      await _insertSchedules(medRow['id'] as int, scheduleTimes);
    }
  }

  Future<void> updateMedication({
    required String patientId,
    required int medicationId,
    required String name,
    String? dosage,
    String? instructions,
    required List<String> scheduleTimes,
    required DateTime startDate,
    DateTime? endDate,
    required MedicationScheduleMode scheduleMode,
    int? intervalHours,
    String? anchorTime,
  }) async {
    await _client
        .from('medications')
        .update({
          'name': name,
          'dosage': dosage,
          'instructions': instructions,
          'start_date': _formatDate(startDate),
          'end_date': endDate != null ? _formatDate(endDate) : null,
          'schedule_mode': scheduleMode.code,
          'interval_hours':
              scheduleMode == MedicationScheduleMode.interval
                  ? intervalHours
                  : null,
          'anchor_time':
              scheduleMode == MedicationScheduleMode.interval
                  ? anchorTime
                  : null,
        })
        .eq('id', medicationId)
        .eq('patient_id', patientId)
        .catchError((Object error) {
      throw _mapError(error, 'Erro ao atualizar medicamento.');
    });

    await _client
        .from('medication_schedules')
        .delete()
        .eq('medication_id', medicationId);

    if (scheduleMode == MedicationScheduleMode.fixedTimes) {
      await _insertSchedules(medicationId, scheduleTimes);
    }
  }

  Future<void> markDoseNotTaken({
    required String patientId,
    required int medicationId,
    required int? scheduleId,
    required String scheduledTime,
    required DateTime scheduledFor,
  }) async {
    final payload = <String, dynamic>{
      'medication_id': medicationId,
      'patient_id': patientId,
      'scheduled_for': _formatDate(scheduledFor),
      'scheduled_time': scheduledTime,
      'taken': false,
      'skipped_reason': MedicationSkippedReason.notTaken,
    };
    if (scheduleId != null && scheduleId > 0) {
      payload['schedule_id'] = scheduleId;
    }

    await _client.from('medication_logs').upsert(
      payload,
      onConflict: 'medication_id,scheduled_for,scheduled_time',
    ).catchError((Object error) {
      throw _mapError(error, 'Erro ao registrar dose nao tomada.');
    });
  }

  Future<void> deactivateMedication({
    required String patientId,
    required int medicationId,
  }) async {
    final yesterday = _dateOnly(DateTime.now()).subtract(const Duration(days: 1));
    await _client
        .from('medications')
        .update({
          'is_active': false,
          'end_date': _formatDate(yesterday),
        })
        .eq('id', medicationId)
        .eq('patient_id', patientId)
        .catchError((Object error) {
      throw _mapError(error, 'Erro ao encerrar medicamento.');
    });
  }

  Future<void> _insertSchedules(int medicationId, List<String> times) async {
    if (times.isEmpty) return;
    final rows = times
        .map((time) => {'medication_id': medicationId, 'time_of_day': time})
        .toList();
    await _client.from('medication_schedules').insert(rows).catchError(
      (Object error) {
        throw _mapError(error, 'Erro ao cadastrar horarios.');
      },
    );
  }

  Map<String, dynamic> _medicationPayload({
    required String patientId,
    required String name,
    String? dosage,
    String? instructions,
    required DateTime startDate,
    DateTime? endDate,
    required MedicationScheduleMode scheduleMode,
    int? intervalHours,
    String? anchorTime,
    required String createdBy,
  }) {
    return {
      'patient_id': patientId,
      'name': name,
      'dosage': dosage,
      'instructions': instructions,
      'start_date': _formatDate(startDate),
      'end_date': endDate != null ? _formatDate(endDate) : null,
      'schedule_mode': scheduleMode.code,
      'interval_hours':
          scheduleMode == MedicationScheduleMode.interval ? intervalHours : null,
      'anchor_time':
          scheduleMode == MedicationScheduleMode.interval ? anchorTime : null,
      'created_by': createdBy,
    };
  }

  AppException _mapError(Object error, String fallback) {
    if (error is PostgrestException) {
      return AppException(error.message);
    }
    if (error is AuthException) {
      return AppException(error.message);
    }
    return AppException(fallback);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
