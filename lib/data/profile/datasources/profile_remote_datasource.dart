import '../../../core/errors/app_exception.dart';
import '../../../core/supabase/supabase_config.dart';
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
}
