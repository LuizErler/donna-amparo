import '../care_team_role.dart';
import '../entities/care_invite_result.dart';
import '../entities/care_team_member.dart';

abstract class CareTeamRepository {
  Future<CareTeamRole?> getCurrentRole(String patientId);

  Future<List<CareTeamMember>> listMembers(String patientId);

  Future<CareInviteResult> createInvite({
    required String patientId,
    required CareTeamRole role,
  });

  Future<void> acceptInvite(String token);

  String buildInviteLink(String token);
}
