import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../domain/profile/entities/update_profile_input.dart';
import '../../../domain/profile/entities/user_profile.dart';

class ProfileRemoteDataSource {
  Future<UserProfile?> getCurrentProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await supabase
        .from('profiles')
        .select('id, full_name, email, phone, avatar_url')
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;
    return UserProfile.fromJson(row);
  }

  Future<void> ensureCurrentProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AppException('Usuario nao autenticado.');
    }

    final existing = await getCurrentProfile();
    if (existing != null) return;

    final metadata = user.userMetadata;
    final fullName = metadata?['nome']?.toString() ??
        metadata?['full_name']?.toString() ??
        '';

    await supabase.from('profiles').upsert({
      'id': user.id,
      'full_name': fullName,
      'email': user.email,
    });
  }

  Future<UserProfile> updateCurrentProfile(UpdateProfileInput input) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Usuario nao autenticado.');
    }

    final row = await supabase
        .from('profiles')
        .update({
          'full_name': input.fullName.trim(),
          'phone': input.phone?.trim().isEmpty == true ? null : input.phone?.trim(),
        })
        .eq('id', userId)
        .select('id, full_name, email, phone, avatar_url')
        .single()
        .catchError((Object error) {
      throw _mapError(error, 'Erro ao atualizar perfil.');
    });

    return UserProfile.fromJson(row);
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
