/// Periodo do dia para agrupamento na UI (Manha/Tarde/Noite).
enum MedicationDayPeriod {
  morning('Manhã'),
  afternoon('Tarde'),
  evening('Noite');

  const MedicationDayPeriod(this.label);

  final String label;

  static MedicationDayPeriod fromHour(int hour) {
    if (hour >= 5 && hour < 12) return MedicationDayPeriod.morning;
    if (hour >= 12 && hour < 18) return MedicationDayPeriod.afternoon;
    return MedicationDayPeriod.evening;
  }
}
