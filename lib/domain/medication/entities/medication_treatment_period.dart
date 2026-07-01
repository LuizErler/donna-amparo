/// Regras de periodo de tratamento (continuo ou com prazo).
class MedicationTreatmentPeriod {
  MedicationTreatmentPeriod._();

  /// Ultimo dia inclusivo: inicio + (duracao - 1) dias corridos.
  static DateTime endDateFromDuration(DateTime startDate, int durationDays) {
    final start = _dateOnly(startDate);
    return start.add(Duration(days: durationDays - 1));
  }

  static bool isActiveOnDay({
    required DateTime day,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final d = _dateOnly(day);
    if (startDate != null) {
      final start = _dateOnly(startDate);
      if (d.isBefore(start)) return false;
    }
    if (endDate != null) {
      final end = _dateOnly(endDate);
      if (d.isAfter(end)) return false;
    }
    return true;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
