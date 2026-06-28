import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/auth/datasources/auth_remote_datasource.dart';
import '../../../data/auth/repositories/auth_repository_impl.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../../../domain/auth/usecases/sign_in.dart';
import '../../../domain/auth/usecases/sign_up.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final signInUseCaseProvider = Provider<SignIn>((ref) {
  return SignIn(ref.watch(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUp>((ref) {
  return SignUp(ref.watch(authRepositoryProvider));
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    signIn: ref.watch(signInUseCaseProvider),
    signUp: ref.watch(signUpUseCaseProvider),
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController({
    required SignIn signIn,
    required SignUp signUp,
  })  : _signIn = signIn,
        _signUp = signUp,
        super(const AsyncValue.data(null));

  final SignIn _signIn;
  final SignUp _signUp;

  bool get isLoading => state.isLoading;

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _signIn(email: email, password: password);
      state = const AsyncValue.data(null);
      return null;
    } on AuthException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return e.message;
    } catch (_) {
      const message = 'Erro inesperado. Tente novamente.';
      state = AsyncValue.error(message, StackTrace.current);
      return message;
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = const AsyncValue.data(null);
      return null;
    } on AuthException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return e.message;
    } catch (_) {
      const message = 'Erro ao criar conta. Tente novamente.';
      state = AsyncValue.error(message, StackTrace.current);
      return message;
    }
  }
}
