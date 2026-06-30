import '../../../domain/profile/entities/user_profile.dart';
import '../../../domain/profile/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<UserProfile?> getCurrentProfile() => _remote.getCurrentProfile();

  @override
  Future<void> ensureCurrentProfile() => _remote.ensureCurrentProfile();
}
