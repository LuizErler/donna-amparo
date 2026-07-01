import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_redirect_url.dart';
import '../../../core/supabase/supabase_config.dart';

class AuthRemoteDataSource {
  SupabaseClient get _client => supabase;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'nome': fullName},
    );

    if (response.user == null) {
      throw const AuthException('Nao foi possivel criar a conta.');
    }
  }

  bool get hasSession => _client.auth.currentSession != null;

  Future<void> signOut() => _client.auth.signOut();

  Future<void> resetPasswordForEmail(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: authRedirectUrl,
    );
  }

  Future<void> updatePassword(String newPassword) {
    return _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
