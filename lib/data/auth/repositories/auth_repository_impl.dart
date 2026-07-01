import '../../../domain/auth/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _remote.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _remote.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
  }

  @override
  bool get isAuthenticated => _remote.hasSession;

  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Future<void> resetPassword({required String email}) =>
      _remote.resetPasswordForEmail(email);

  @override
  Future<void> updatePassword({required String newPassword}) =>
      _remote.updatePassword(newPassword);
}
