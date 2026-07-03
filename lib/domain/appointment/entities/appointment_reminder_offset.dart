/// Offset de alerta antes da consulta (minutos), estilo Calendario iOS.
enum AppointmentReminderOffset {
  minutes5(5, '5 minutos antes'),
  minutes10(10, '10 minutos antes'),
  minutes15(15, '15 minutos antes'),
  minutes30(30, '30 minutos antes'),
  hour1(60, '1 hora antes'),
  hours2(120, '2 horas antes'),
  day1(1440, '1 dia antes'),
  days2(2880, '2 dias antes'),
  week1(10080, '1 semana antes');

  const AppointmentReminderOffset(this.minutesBefore, this.label);

  final int minutesBefore;
  final String label;

  static const maxPerList = 5;

  static const List<AppointmentReminderOffset> pickerOptions = [
    minutes5,
    minutes10,
    minutes15,
    minutes30,
    hour1,
    hours2,
    day1,
    days2,
    week1,
  ];

  static const defaultPersonal = [AppointmentReminderOffset.day1];

  static AppointmentReminderOffset? fromMinutes(int minutes) {
    for (final option in pickerOptions) {
      if (option.minutesBefore == minutes) return option;
    }
    return null;
  }

  static List<AppointmentReminderOffset> fromMinutesList(List<dynamic>? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final result = <AppointmentReminderOffset>[];
    for (final value in raw) {
      final minutes = value is int ? value : int.tryParse('$value');
      if (minutes == null) continue;
      final offset = fromMinutes(minutes);
      if (offset != null && !result.contains(offset)) {
        result.add(offset);
      }
    }
    return sorted(result);
  }

  static List<int> toMinutesList(List<AppointmentReminderOffset> offsets) {
    return sorted(offsets).map((o) => o.minutesBefore).toList();
  }

  static List<AppointmentReminderOffset> sorted(
    List<AppointmentReminderOffset> offsets,
  ) {
    final copy = List<AppointmentReminderOffset>.from(offsets);
    copy.sort((a, b) => b.minutesBefore.compareTo(a.minutesBefore));
    return copy;
  }

  static String formatList(List<AppointmentReminderOffset> offsets) {
    if (offsets.isEmpty) return 'Nenhum';
    return sorted(offsets).map((o) => o.label).join(', ');
  }
}
