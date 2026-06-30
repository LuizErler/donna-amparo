class CareInviteResult {
  const CareInviteResult({
    required this.token,
    required this.roleCode,
    required this.expiresAt,
  });

  final String token;
  final String roleCode;
  final DateTime expiresAt;
}
