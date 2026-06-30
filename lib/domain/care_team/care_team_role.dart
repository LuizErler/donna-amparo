/// Papeis do circulo de cuidado por paciente (`care_teams.role`).
enum CareTeamRole {
  /// Cuidador Admin — configuracao, convites, alterar papeis.
  admin('admin', 'Cuidador Admin'),

  /// Cuidador — cadastra consultas, medicamentos e vitais.
  caregiver('caregiver', 'Cuidador'),

  /// Cuidador Basico — visualiza, marca doses e registra vitais.
  caregiverBasic('caregiver_basic', 'Cuidador Basico'),

  /// Observador — somente leitura.
  observer('observer', 'Observador');

  const CareTeamRole(this.code, this.label);

  final String code;
  final String label;

  static CareTeamRole? fromCode(String? code) {
    if (code == null) return null;
    for (final role in CareTeamRole.values) {
      if (role.code == code) return role;
    }
    return null;
  }

  bool get canManageTeam => this == CareTeamRole.admin;

  bool get canCreateMedsAndAppointments =>
      this == CareTeamRole.admin || this == CareTeamRole.caregiver;

  bool get canLogDosesAndVitals =>
      this == CareTeamRole.admin ||
      this == CareTeamRole.caregiver ||
      this == CareTeamRole.caregiverBasic;

  bool get isReadOnly => this == CareTeamRole.observer;
}
