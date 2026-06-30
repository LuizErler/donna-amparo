import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Perfil do cuidador logado (`profiles`).
final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  return ref.watch(profileRepositoryProvider).getCurrentProfile();
});

/// Paciente ativo do cuidador (MVP: primeiro vinculo aceito).
final activePatientProvider = FutureProvider<Patient?>((ref) async {
  return ref.watch(patientRepositoryProvider).getActivePatient();
});

/// True quando o usuario ja concluiu onboarding (tem paciente vinculado).
final hasActivePatientProvider = FutureProvider<bool>((ref) async {
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
