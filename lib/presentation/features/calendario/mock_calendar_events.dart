import '../../../domain/calendar/entities/calendar_event.dart';

/// Consultas e compromissos mock (Epic 5 / manual). Medicamentos vêm do Supabase.
class MockCalendarEvents {
  MockCalendarEvents._();

  static final List<CalendarEvent> _staticEvents = [
    CalendarEvent(
      id: 'appt-1',
      start: DateTime(2026, 6, 19, 10, 30),
      title: 'Cardiologia',
      subtitle: 'Dra. Helena Vasconcelos · Clinica CorVida',
      type: CalendarEventType.appointment,
      sourceId: 'consulta-cardio',
    ),
    CalendarEvent(
      id: 'appt-2',
      start: DateTime(2026, 7, 1, 14, 0),
      title: 'Geriatria',
      subtitle: 'Dr. Augusto Ramires · Consultorio particular',
      type: CalendarEventType.appointment,
      sourceId: 'consulta-geriatria',
    ),
    CalendarEvent(
      id: 'manual-1',
      start: DateTime(2026, 6, 28, 15, 0),
      title: 'Fisioterapia',
      subtitle: 'Sessao semanal · Clinica Movimento',
      type: CalendarEventType.manual,
    ),
  ];

  static List<CalendarEvent> forDay(DateTime day) {
    return _staticEvents.where((e) => _isSameDay(e.start, day)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  static Set<CalendarEventType> typesOnDay(DateTime day) {
    return _staticEvents
        .where((e) => _isSameDay(e.start, day))
        .map((e) => e.type)
        .toSet();
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
