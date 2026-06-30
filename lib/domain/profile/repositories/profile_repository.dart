import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getCurrentProfile();

  /// Garante linha em profiles (usuarios criados antes do trigger no signup).
  Future<void> ensureCurrentProfile();
}
