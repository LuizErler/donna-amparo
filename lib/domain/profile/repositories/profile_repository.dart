import '../entities/update_profile_input.dart';
import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getCurrentProfile();

  /// Garante linha em profiles (usuarios criados antes do trigger no signup).
  Future<void> ensureCurrentProfile();

  Future<UserProfile> updateCurrentProfile(UpdateProfileInput input);
}
