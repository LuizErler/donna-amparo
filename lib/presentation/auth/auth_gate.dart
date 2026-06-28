import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import 'providers/auth_providers.dart';
import 'screens/login_screen.dart';
import '../shell/main_navigation.dart';

/// Porteiro global: restaura sessao Supabase ao reabrir o app.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppConfig.enableAuth) {
      return const MainNavigation();
    }

    final sessionAsync = ref.watch(authSessionProvider);

    return sessionAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const LoginScreen(),
      data: (isAuthenticated) =>
          isAuthenticated ? const MainNavigation() : const LoginScreen(),
    );
  }
}
