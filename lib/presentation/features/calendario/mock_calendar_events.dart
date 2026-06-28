import '../../../domain/calendar/entities/calendar_event.dart';

/// Dados mock agregando consultas (Epic 5) e doses (Epic 4).
/// Substituir por CalendarRepositoryImpl na integracao real (Task 6.3).
class MockCalendarEvents {
  MockCalendarEvents._();

  static final List<CalendarEvent> all = [
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
    ..._dailyMedicationDoses(),
  ];

  static List<CalendarEvent> forDay(DateTime day) {
    return all.where((e) => _isSameDay(e.start, day)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  static bool hasEventsOnDay(DateTime day) {
    return all.any((e) => _isSameDay(e.start, day));
  }

  static Set<CalendarEventType> typesOnDay(DateTime day) {
    return all
        .where((e) => _isSameDay(e.start, day))
        .map((e) => e.type)
        .toSet();
  }

  static List<CalendarEvent> _dailyMedicationDoses() {
    const doses = [
      (time: '08:00', name: 'Losartana 50 mg', note: 'Com agua, apos refeicao'),
      (time: '08:00', name: 'Metformina 500 mg', note: 'Durante o cafe da manha'),
      (time: '12:00', name: 'AAS 100 mg', note: 'Com agua'),
      (time: '12:00', name: 'Metformina 500 mg', note: 'Durante o almoco'),
      (time: '20:00', name: 'Atorvastatina 20 mg', note: 'Preferencialmente a noite'),
      (time: '20:00', name: 'Losartana 50 mg', note: 'Com agua, apos jantar'),
      (time: '22:00', name: 'Clonazepam 0.5 mg', note: 'Antes de dormir'),
    ];

    final events = <CalendarEvent>[];
    for (var dayOffset = -7; dayOffset <= 14; dayOffset++) {
      final base = DateTime(2026, 6, 27).add(Duration(days: dayOffset));
      for (var i = 0; i < doses.length; i++) {
        final dose = doses[i];
        final parts = dose.time.split(':');
        events.add(
          CalendarEvent(
            id: 'med-$dayOffset-$i',
            start: DateTime(
              base.year,
              base.month,
              base.day,
              int.parse(parts[0]),
              int.parse(parts[1]),
            ),
            title: dose.name,
            subtitle: dose.note,
            type: CalendarEventType.medicationDose,
            sourceId: 'med-${dose.name.hashCode}',
          ),
        );
      }
    }
    return events;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
