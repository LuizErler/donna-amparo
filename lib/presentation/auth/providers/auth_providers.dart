import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/auth/auth_error_messages.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../data/auth/datasources/auth_remote_datasource.dart';
import '../../../data/auth/repositories/auth_repository_impl.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../../../domain/auth/usecases/reset_password.dart';
import '../../../domain/auth/usecases/sign_in.dart';
import '../../../domain/auth/usecases/sign_up.dart';
import '../../../domain/auth/usecases/update_password.dart';
import '../../care/providers/care_providers.dart';
import '../../care/providers/care_team_providers.dart';
import '../../push/providers/push_providers.dart';

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

final resetPasswordUseCaseProvider = Provider<ResetPassword>((ref) {
  return ResetPassword(ref.watch(authRepositoryProvider));
});

final updatePasswordUseCaseProvider = Provider<UpdatePassword>((ref) {
  return UpdatePassword(ref.watch(authRepositoryProvider));
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

/// True quando o usuario abriu o link de recuperacao de senha do e-mail.
final passwordRecoveryProvider =
    StateNotifierProvider<PasswordRecoveryNotifier, bool>((ref) {
  return PasswordRecoveryNotifier();
});

class PasswordRecoveryNotifier extends StateNotifier<bool> {
  PasswordRecoveryNotifier() : super(false) {
    if (!AppConfig.enableAuth) return;

    _subscription = supabase.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.passwordRecovery) {
        state = true;
      }
    });
  }

  StreamSubscription<AuthState>? _subscription;

  void clear() => state = false;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    signIn: ref.watch(signInUseCaseProvider),
    signUp: ref.watch(signUpUseCaseProvider),
    resetPassword: ref.watch(resetPasswordUseCaseProvider),
    updatePassword: ref.watch(updatePasswordUseCaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
    onPasswordUpdated: () =>
        ref.read(passwordRecoveryProvider.notifier).clear(),
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController({
    required SignIn signIn,
    required SignUp signUp,
    required ResetPassword resetPassword,
    required UpdatePassword updatePassword,
    required AuthRepository authRepository,
    required void Function() onPasswordUpdated,
  })  : _signIn = signIn,
        _signUp = signUp,
        _resetPassword = resetPassword,
        _updatePassword = updatePassword,
        _authRepository = authRepository,
        _onPasswordUpdated = onPasswordUpdated,
        super(const AsyncValue.data(null));

  final SignIn _signIn;
  final SignUp _signUp;
  final ResetPassword _resetPassword;
  final UpdatePassword _updatePassword;
  final AuthRepository _authRepository;
  final void Function() _onPasswordUpdated;

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
      final message = mapAuthError(e.message);
      state = AsyncValue.error(message, StackTrace.current);
      return message;
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
      final message = mapAuthError(e.message);
      state = AsyncValue.error(message, StackTrace.current);
      return message;
    } catch (_) {
      const message = 'Erro ao criar conta. Tente novamente.';
      state = AsyncValue.error(message, StackTrace.current);
      return message;
    }
  }

  Future<String?> requestPasswordReset({required String email}) async {
    state = const AsyncValue.loading();
    try {
      await _resetPassword(email: email);
      state = const AsyncValue.data(null);
      return null;
    } on AuthException catch (e) {
      final message = mapAuthError(e.message);
      state = AsyncValue.error(message, StackTrace.current);
      return message;
    } catch (_) {
      const message = 'Erro ao enviar e-mail de recuperacao.';
      state = AsyncValue.error(message, StackTrace.current);
      return message;
    }
  }

  Future<String?> changePassword({required String newPassword}) async {
    state = const AsyncValue.loading();
    try {
      await _updatePassword(newPassword: newPassword);
      _onPasswordUpdated();
      state = const AsyncValue.data(null);
      return null;
    } on AuthException catch (e) {
      final message = mapAuthError(e.message);
      state = AsyncValue.error(message, StackTrace.current);
      return message;
    } catch (_) {
      const message = 'Erro ao atualizar senha.';
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
      final message = mapAuthError(e.message);
      state = AsyncValue.error(message, StackTrace.current);
      return message;
    } catch (_) {
      const message = 'Erro ao encerrar sessao.';
      state = AsyncValue.error(message, StackTrace.current);
      return message;
    }
  }
}

/// Encerra sessao Supabase e limpa cache de perfil/paciente.
Future<String?> performSignOut(WidgetRef ref) async {
  final profileId = ref.read(currentProfileProvider).valueOrNull?.id;
  if (profileId != null) {
    await unregisterPushTokenForProfile(ref, profileId: profileId);
  }

  final error = await ref.read(authControllerProvider.notifier).signOut();
  ref.invalidate(currentProfileProvider);
  ref.invalidate(activePatientProvider);
  ref.invalidate(hasActivePatientProvider);
  ref.invalidate(familyMembersProvider);
  ref.invalidate(currentCareRoleProvider);
  ref.read(passwordRecoveryProvider.notifier).clear();
  return error;
}
