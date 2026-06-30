import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../data/auth/datasources/auth_remote_datasource.dart';
import '../../../data/auth/repositories/auth_repository_impl.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../../../domain/auth/usecases/sign_in.dart';
import '../../../domain/auth/usecases/sign_up.dart';
import '../../care/providers/care_providers.dart';

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

/// Emite true quando ha sessao Supabase valida (persistida entre aberturas do app).
final authSessionProvider = StreamProvider<bool>((ref) {
  if (!AppConfig.enableAuth) {
    return Stream.value(true);
  }

  final auth = supabase.auth;

  return Stream.multi((controller) {
    controller.add(auth.currentSession != null);

    final subscription = auth.onAuthStateChange.listen((event) {
      controller.add(event.session != null);
    });

    controller.onCancel = () => subscription.cancel();
  });
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    signIn: ref.watch(signInUseCaseProvider),
    signUp: ref.watch(signUpUseCaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController({
    required SignIn signIn,
    required SignUp signUp,
    required AuthRepository authRepository,
  })  : _signIn = signIn,
        _signUp = signUp,
        _authRepository = authRepository,
        super(const AsyncValue.data(null));

  final SignIn _signIn;
  final SignUp _signUp;
  final AuthRepository _authRepository;

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

  Future<String?> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
      return null;
    } on AuthException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return e.message;
    } catch (_) {
      const message = 'Erro ao encerrar sessao.';
      state = AsyncValue.error(message, StackTrace.current);
      return message;
    }
  }
}

/// Encerra sessao Supabase e limpa cache de perfil/paciente.
Future<String?> performSignOut(WidgetRef ref) async {
  final error = await ref.read(authControllerProvider.notifier).signOut();
  ref.invalidate(currentProfileProvider);
  ref.invalidate(activePatientProvider);
  ref.invalidate(hasActivePatientProvider);
  return error;
}
