import '../care_team_role.dart';

class CareTeamMember {
  const CareTeamMember({
    required this.profileId,
    required this.fullName,
    required this.role,
    this.email,
    this.acceptedAt,
    this.isCurrentUser = false,
  });

  final String profileId;
  final String fullName;
  final String? email;
  final CareTeamRole role;
  final DateTime? acceptedAt;
  final bool isCurrentUser;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  bool get isAdmin => role == CareTeamRole.admin;
}
