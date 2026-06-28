enum CalendarEventType {
  appointment,
  medicationDose,
  manual,
}

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.start,
    required this.title,
    required this.subtitle,
    required this.type,
    this.sourceId,
  });

  final String id;
  final DateTime start;
  final String title;
  final String subtitle;
  final CalendarEventType type;
  final String? sourceId;
}
