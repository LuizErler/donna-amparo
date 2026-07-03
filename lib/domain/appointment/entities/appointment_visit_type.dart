enum AppointmentVisitType {
  consulta('consulta', 'Consulta'),
  exame('exame', 'Exame');

  const AppointmentVisitType(this.code, this.label);

  final String code;
  final String label;

  static AppointmentVisitType fromCode(String? code) {
    for (final type in AppointmentVisitType.values) {
      if (type.code == code) return type;
    }
    return AppointmentVisitType.consulta;
  }
}
