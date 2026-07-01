import '../../../core/errors/app_exception.dart';
import '../../../domain/care_team/care_team_role.dart';
import '../../../domain/care_team/entities/care_invite_result.dart';
import '../../../domain/care_team/entities/care_team_member.dart';
import '../../../domain/care_team/repositories/care_team_repository.dart';
import '../datasources/care_team_remote_datasource.dart';

class CareTeamRepositoryImpl implements CareTeamRepository {
  CareTeamRepositoryImpl(this._remote);

  final CareTeamRemoteDataSource _remote;

  static const inviteableRoles = [
    CareTeamRole.caregiver,
    CareTeamRole.observer,
  ];

  /// Papeis que o admin pode atribuir a membros ja aceitos.
  static const editableRoles = [
    CareTeamRole.caregiver,
    CareTeamRole.caregiverBasic,
    CareTeamRole.observer,
  ];

  @override
  Future<CareTeamRole?> getCurrentRole(String patientId) =>
      _remote.getCurrentRole(patientId);

  @override
  Future<List<CareTeamMember>> listMembers(String patientId) =>
      _remote.listMembers(patientId);

  @override
  Future<CareInviteResult> createInvite({
    required String patientId,
    required CareTeamRole role,
  }) {
    if (!inviteableRoles.contains(role)) {
      throw ArgumentError('Papel nao permitido em convite: ${role.code}');
    }
    return _remote.createInvite(patientId: patientId, role: role);
  }

  @override
  Future<void> acceptInvite(String token) => _remote.acceptInvite(token);

  @override
  Future<void> updateMemberRole({
    required String patientId,
    required String profileId,
    required CareTeamRole newRole,
  }) {
    if (!editableRoles.contains(newRole)) {
      throw const AppException('Papel nao permitido para este membro.');
    }
    return _remote.updateMemberRole(
      patientId: patientId,
      profileId: profileId,
      role: newRole,
    );
  }

  @override
  Future<void> removeMember({
    required String patientId,
    required String profileId,
  }) =>
      _remote.removeMember(patientId: patientId, profileId: profileId);

  @override
  String buildInviteLink(String token) {
    final base = Uri.base;
    final path = base.path.isEmpty ? '/' : base.path;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: path,
      queryParameters: {'invite': token},
    ).toString();
  }
}
