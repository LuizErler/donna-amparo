import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../domain/appointment/entities/appointment.dart';

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
    reminder_24h,
    notify_team
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
