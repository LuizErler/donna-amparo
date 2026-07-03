import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../domain/hydration/entities/hydration_log.dart';
import '../../../domain/hydration/entities/hydration_status.dart';

class HydrationRemoteDataSource {
  SupabaseClient get _client => supabase;

  Future<HydrationStatus> getStatus({required String patientId}) async {
    final rows = await _client
        .from('hydration_logs')
        .select('id, patient_id, recorded_at, recorded_by, notes')
        .eq('patient_id', patientId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .catchError((Object error) {
      throw _mapError(error, 'Erro ao carregar hidratacao.');
    });

    final list = rows as List<dynamic>;
    if (list.isEmpty) {
      return const HydrationStatus();
    }

    return HydrationStatus(
      lastLog: HydrationLog.fromJson(list.first as Map<String, dynamic>),
    );
  }

  Future<void> recordHydration({required String patientId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Usuario nao autenticado.');
    }

    await _client.from('hydration_logs').insert({
      'patient_id': patientId,
      'recorded_by': userId,
    }).catchError((Object error) {
      throw _mapError(error, 'Erro ao registrar hidratacao.');
    });
  }

  AppException _mapError(Object error, String fallback) {
    if (error is PostgrestException && error.message.isNotEmpty) {
      return AppException(error.message);
    }
    return AppException(fallback);
  }
}
