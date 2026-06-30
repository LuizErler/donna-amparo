import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/care_team/datasources/care_team_remote_datasource.dart';
import '../../../data/care_team/repositories/care_team_repository_impl.dart';
import '../../../domain/care_team/care_team_role.dart';
import '../../../domain/care_team/entities/care_team_member.dart';
import '../../../domain/care_team/repositories/care_team_repository.dart';
import 'care_providers.dart';

final careTeamRemoteDataSourceProvider =
    Provider<CareTeamRemoteDataSource>((ref) {
  return CareTeamRemoteDataSource();
});

final careTeamRepositoryProvider = Provider<CareTeamRepository>((ref) {
  return CareTeamRepositoryImpl(ref.watch(careTeamRemoteDataSourceProvider));
});

/// Token de convite lido da URL (?invite=...) ao abrir o app.
final pendingInviteTokenProvider = StateProvider<String?>((ref) {
  final token = Uri.base.queryParameters['invite'];
  if (token == null || token.trim().isEmpty) return null;
  return token.trim();
});

/// Papel do usuario logado no paciente ativo.
final currentCareRoleProvider = FutureProvider<CareTeamRole?>((ref) async {
  final patient = await ref.watch(activePatientProvider.future);
  if (patient == null) return null;
  return ref.watch(careTeamRepositoryProvider).getCurrentRole(patient.id);
});

/// Membros aceitos do circulo familiar do paciente ativo.
final familyMembersProvider = FutureProvider<List<CareTeamMember>>((ref) async {
  final patient = await ref.watch(activePatientProvider.future);
  if (patient == null) return [];
  return ref.watch(careTeamRepositoryProvider).listMembers(patient.id);
});

/// Aceita convite pendente da URL apos autenticacao.
final acceptPendingInviteProvider = FutureProvider<void>((ref) async {
  final token = ref.watch(pendingInviteTokenProvider);
  if (token == null) return;

  await ref.read(careTeamRepositoryProvider).acceptInvite(token);
  ref.read(pendingInviteTokenProvider.notifier).state = null;
  invalidateCareContext(ref);
  ref.invalidate(familyMembersProvider);
  ref.invalidate(currentCareRoleProvider);
});

void invalidateFamilyProviders(Ref ref) {
  ref.invalidate(familyMembersProvider);
  ref.invalidate(currentCareRoleProvider);
}
