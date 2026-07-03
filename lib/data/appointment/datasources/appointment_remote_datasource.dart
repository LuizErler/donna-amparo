import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../domain/appointment/entities/appointment.dart';
import '../../../domain/appointment/entities/appointment_reminder_offset.dart';

class AppointmentRemoteDataSource {
  SupabaseClient get _client => supabase;

  static const _appointmentSelect = '''
    id,
    title,
    doctor,
    specialty,
    location,
    appointment_date,
    visit_type,
    notes,
    reminder_offsets_minutes,
    team_notify_offsets_minutes
  ''';

  Future<List<Appointment>> listAppointments({
    required String patientId,
  }) async {
    final rows = await _client
        .from('appointments')
        .select(_appointmentSelect)
        .eq('patient_id', patientId)
        .order('appointment_date', ascending: true)
        .catchError((Object error) {
      throw _mapError(error, 'Erro ao carregar consultas.');
    });

    return (rows as List<dynamic>)
        .map((r) => Appointment.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<Appointment>> listAppointmentsInRange({
    required String patientId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final rows = await _client
        .from('appointments')
        .select(_appointmentSelect)
        .eq('patient_id', patientId)
        .gte('appointment_date', rangeStart.toUtc().toIso8601String())
        .lte('appointment_date', rangeEnd.toUtc().toIso8601String())
        .order('appointment_date', ascending: true)
        .catchError((Object error) {
      throw _mapError(error, 'Erro ao carregar consultas do periodo.');
    });

    return (rows as List<dynamic>)
        .map((r) => Appointment.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> createAppointment({
    required String patientId,
    required String specialty,
    required DateTime appointmentDate,
    String? doctor,
    String? location,
    required String visitType,
    String? notes,
    required List<AppointmentReminderOffset> personalReminders,
    required List<AppointmentReminderOffset> teamNotifyReminders,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Usuario nao autenticado.');
    }

    await _client.from('appointments').insert({
      'patient_id': patientId,
      'title': specialty,
      'specialty': specialty,
      'doctor': doctor,
      'location': location,
      'appointment_date': appointmentDate.toUtc().toIso8601String(),
      'visit_type': visitType,
      'notes': notes,
      'reminder_offsets_minutes':
          AppointmentReminderOffset.toMinutesList(personalReminders),
      'team_notify_offsets_minutes':
          AppointmentReminderOffset.toMinutesList(teamNotifyReminders),
      'created_by': userId,
    }).catchError((Object error) {
      throw _mapError(error, 'Erro ao agendar consulta.');
    });
  }

  Future<void> updateAppointment({
    required String patientId,
    required int appointmentId,
    required String specialty,
    required DateTime appointmentDate,
    String? doctor,
    String? location,
    required String visitType,
    String? notes,
    required List<AppointmentReminderOffset> personalReminders,
    required List<AppointmentReminderOffset> teamNotifyReminders,
  }) async {
    await _client
        .from('appointments')
        .update({
          'title': specialty,
          'specialty': specialty,
          'doctor': doctor,
          'location': location,
          'appointment_date': appointmentDate.toUtc().toIso8601String(),
          'visit_type': visitType,
          'notes': notes,
          'reminder_offsets_minutes':
              AppointmentReminderOffset.toMinutesList(personalReminders),
          'team_notify_offsets_minutes':
              AppointmentReminderOffset.toMinutesList(teamNotifyReminders),
        })
        .eq('id', appointmentId)
        .eq('patient_id', patientId)
        .catchError((Object error) {
      throw _mapError(error, 'Erro ao atualizar consulta.');
    });
  }

  Future<void> deleteAppointment({
    required String patientId,
    required int appointmentId,
  }) async {
    await _client
        .from('appointments')
        .delete()
        .eq('id', appointmentId)
        .eq('patient_id', patientId)
        .catchError((Object error) {
      throw _mapError(error, 'Erro ao cancelar consulta.');
    });
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
}
