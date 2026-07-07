import 'package:flutter_test/flutter_test.dart';

import 'package:donna_amparo/domain/calendar/entities/calendar_event.dart';
import 'package:donna_amparo/domain/medication/entities/medication_day_period.dart';
import 'package:donna_amparo/domain/medication/entities/medication_dose.dart';
import 'package:donna_amparo/presentation/calendar/calendar_event_mapper.dart';

void main() {
  test('findDoseForEvent retorna dose correspondente ao evento', () {
    final scheduledFor = DateTime(2026, 7, 7);
    final dose = MedicationDose(
      medicationId: 42,
      scheduleId: 1,
      name: 'Losartana',
      instructions: '',
      timeLabel: '08:00',
      scheduledTime: '08:00',
      scheduledFor: scheduledFor,
      period: MedicationDayPeriod.morning,
      taken: false,
      isOverdue: false,
    );

    final event = CalendarEventMapper.fromMedicationDose(dose);
    final found = CalendarEventMapper.findDoseForEvent([dose], event);

    expect(found, dose);
    expect(event.type, CalendarEventType.medicationDose);
  });
}
