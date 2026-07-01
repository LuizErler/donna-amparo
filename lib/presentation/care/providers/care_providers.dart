import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../data/patient/datasources/patient_remote_datasource.dart';
import '../../../data/patient/repositories/patient_repository_impl.dart';
import '../../../data/profile/datasources/profile_remote_datasource.dart';
import '../../../data/profile/repositories/profile_repository_impl.dart';
import '../../../domain/patient/entities/patient.dart';
import '../../../domain/patient/repositories/patient_repository.dart';
import '../../../domain/profile/entities/user_profile.dart';
import '../../../domain/profile/repositories/profile_repository.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));
});

final patientRemoteDataSourceProvider = Provider<PatientRemoteDataSource>((ref) {
  return PatientRemoteDataSource();
});

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepositoryImpl(
    ref.watch(patientRemoteDataSourceProvider),
    ref.watch(profileRepositoryProvider),
  );
});

/// Dispara recarga de perfil/paciente a cada mudanca de sessao Supabase.
final authStateVersionProvider = StreamProvider<int>((ref) {
  if (!AppConfig.enableAuth) {
    return Stream.value(0);
  }

  return Stream.multi((controller) {
    controller.add(0);
    final subscription = supabase.auth.onAuthStateChange.listen((_) {
      controller.add(DateTime.now().millisecondsSinceEpoch);
    });
    controller.onCancel = () => subscription.cancel();
  });
});

/// Perfil do cuidador logado (`profiles`).
final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  ref.watch(authStateVersionProvider);

  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;

  final repo = ref.watch(profileRepositoryProvider);
  var profile = await repo.getCurrentProfile();
  if (profile == null) {
    await repo.ensureCurrentProfile();
    profile = await repo.getCurrentProfile();
  }
  return profile;
});

/// Paciente ativo do cuidador (MVP: primeiro vinculo aceito).
final activePatientProvider = FutureProvider<Patient?>((ref) async {
  ref.watch(authStateVersionProvider);

  if (supabase.auth.currentUser?.id == null) return null;
  return ref.watch(patientRepositoryProvider).getActivePatient();
});

/// True quando o usuario ja concluiu onboarding (tem paciente vinculado).
final hasActivePatientProvider = FutureProvider<bool>((ref) async {
  ref.watch(authStateVersionProvider);

  if (supabase.auth.currentUser?.id == null) return false;
  return ref.watch(patientRepositoryProvider).hasActivePatient();
});

class CareContext {
  const CareContext({
    this.profile,
    this.patient,
  });

  final UserProfile? profile;
  final Patient? patient;

  String get caregiverFirstName => profile?.firstName ?? 'Cuidador';

  String get patientName => patient?.fullName ?? 'paciente';

  String get contextLabel => 'Cuidando de $patientName';

  String get profileInitials => profile?.initials ?? '?';
}

/// Dados agregados para cabecalho e home.
final careContextProvider = Provider<AsyncValue<CareContext>>((ref) {
  final profileAsync = ref.watch(currentProfileProvider);
  final patientAsync = ref.watch(activePatientProvider);

  if (profileAsync.isLoading || patientAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (profileAsync.hasError) {
    return AsyncValue.error(profileAsync.error!, profileAsync.stackTrace!);
  }
  if (patientAsync.hasError) {
    return AsyncValue.error(patientAsync.error!, patientAsync.stackTrace!);
  }

  return AsyncValue.data(CareContext(
    profile: profileAsync.value,
    patient: patientAsync.value,
  ));
});

void invalidateCareContext(Ref ref) {
  ref.invalidate(currentProfileProvider);
  ref.invalidate(activePatientProvider);
  ref.invalidate(hasActivePatientProvider);
}
