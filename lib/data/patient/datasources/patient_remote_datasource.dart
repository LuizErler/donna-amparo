import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../domain/patient/entities/patient.dart';

class PatientRemoteDataSource {
  Future<Patient?> getActivePatient() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await supabase
        .from('care_teams')
        .select('patients(id, full_name, date_of_birth, allergies, emergency_contact)')
        .eq('profile_id', userId)
        .not('accepted_at', 'is', null)
        .order('created_at', ascending: true)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;

    final patientJson = row['patients'];
    if (patientJson is! Map<String, dynamic>) return null;

    return Patient.fromJson(patientJson);
  }

  Future<Patient> createPatient({
    required String fullName,
    required DateTime dateOfBirth,
    String? allergies,
    String? emergencyContact,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Usuario nao autenticado.');
    }

    final row = await supabase
        .from('patients')
        .insert({
          'full_name': fullName,
          'date_of_birth': _formatDate(dateOfBirth),
          'allergies': allergies,
          'emergency_contact': emergencyContact,
          'created_by': userId,
        })
        .select('id, full_name, date_of_birth, allergies, emergency_contact')
        .single()
        .catchError((Object error) {
      throw _mapSupabaseError(error, 'Erro ao cadastrar paciente.');
    });

    return Patient.fromJson(row);
  }

  Future<void> createAdminMembership(String patientId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Usuario nao autenticado.');
    }

    await supabase.from('care_teams').insert({
      'profile_id': userId,
      'patient_id': patientId,
      'role': 'admin',
      'accepted_at': DateTime.now().toUtc().toIso8601String(),
    }).catchError((Object error) {
      throw _mapSupabaseError(error, 'Erro ao vincular cuidador ao paciente.');
    });
  }

  AppException _mapSupabaseError(Object error, String fallback) {
    if (error is PostgrestException) {
      return AppException(error.message);
    }
    if (error is AuthException) {
      return AppException(error.message);
    }
    return AppException(fallback);
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
