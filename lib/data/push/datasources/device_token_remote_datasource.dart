import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../domain/push/entities/device_token_platform.dart';

class DeviceTokenRemoteDataSource {
  SupabaseClient get _client => supabase;

  Future<void> upsertToken({
    required String profileId,
    required String token,
    required DeviceTokenPlatform platform,
    String? appVersion,
  }) async {
    await _client.from('device_tokens').upsert(
      {
        'profile_id': profileId,
        'token': token,
        'platform': platform.code,
        'app_version': appVersion,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'profile_id,token',
    ).catchError((Object error) {
      throw _mapError(error, 'Erro ao registrar token de notificação.');
    });
  }

  Future<void> deleteToken({
    required String profileId,
    required String token,
  }) async {
    await _client
        .from('device_tokens')
        .delete()
        .eq('profile_id', profileId)
        .eq('token', token)
        .catchError((Object error) {
      throw _mapError(error, 'Erro ao remover token de notificação.');
    });
  }

  Never _mapError(Object error, String fallback) {
    if (error is PostgrestException) {
      throw AppException(error.message);
    }
    throw AppException(fallback);
  }
}
