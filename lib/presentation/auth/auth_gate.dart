import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../care/providers/care_providers.dart';
import '../onboarding/screens/patient_onboarding_screen.dart';
import 'providers/auth_providers.dart';
import 'screens/login_screen.dart';
import '../shell/main_navigation.dart';

/// Porteiro global: sessao Supabase + onboarding de paciente.
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
      data: (isAuthenticated) {
        if (!isAuthenticated) return const LoginScreen();

        final onboardingAsync = ref.watch(hasActivePatientProvider);
        return onboardingAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const PatientOnboardingScreen(),
          data: (hasPatient) =>
              hasPatient ? const MainNavigation() : const PatientOnboardingScreen(),
        );
      },
    );
  }
}
