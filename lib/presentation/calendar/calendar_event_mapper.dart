import '../../domain/calendar/entities/calendar_event.dart';
import '../../domain/medication/entities/medication_dose.dart';

class CalendarEventMapper {
  CalendarEventMapper._();

  static CalendarEvent fromMedicationDose(MedicationDose dose) {
    final parts = dose.scheduledTime.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return CalendarEvent(
      id: 'med-${dose.medicationId}-${dose.scheduledFor.millisecondsSinceEpoch}-${dose.scheduledTime}',
      start: DateTime(
        dose.scheduledFor.year,
        dose.scheduledFor.month,
        dose.scheduledFor.day,
        hour,
        minute,
      ),
      title: dose.displayName,
      subtitle: _subtitleForDose(dose),
      type: CalendarEventType.medicationDose,
      sourceId: dose.medicationId.toString(),
    );
  }

  static String _subtitleForDose(MedicationDose dose) {
    if (dose.taken) return 'Confirmada';
    if (dose.isMarkedNotTaken) return 'Nao tomada';
    if (dose.instructions.trim().isNotEmpty) return dose.instructions.trim();
    return 'Dose do dia';
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static List<MedicationDose> dosesOnDay(
    List<MedicationDose> doses,
    DateTime day,
  ) {
    return doses.where((d) => isSameDay(d.scheduledFor, day)).toList();
  }
}
