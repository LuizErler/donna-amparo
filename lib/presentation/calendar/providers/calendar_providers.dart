import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/medication/entities/medication_dose.dart';
import '../../care/providers/care_providers.dart';
import '../../medication/providers/medication_providers.dart';

/// Mes visivel no calendario (ano + mes).
typedef CalendarMonthKey = ({int year, int month});

CalendarMonthKey calendarMonthKey(DateTime day) => (year: day.year, month: day.month);

DateTime _monthRangeStart(CalendarMonthKey key) {
  final first = DateTime(key.year, key.month, 1);
  return first.subtract(const Duration(days: 7));
}

DateTime _monthRangeEnd(CalendarMonthKey key) {
  final nextMonth = key.month == 12
      ? DateTime(key.year + 1, 1, 1)
      : DateTime(key.year, key.month + 1, 1);
  return nextMonth.add(const Duration(days: 7));
}

/// Doses de medicamentos no intervalo do mes visivel (+ margem para semanas cortadas).
final medicationCalendarDosesProvider =
    FutureProvider.family<List<MedicationDose>, CalendarMonthKey>((ref, month) async {
  ref.watch(authStateVersionProvider);

  final patient = await ref.watch(activePatientProvider.future);
  if (patient == null) return [];

  return ref.watch(medicationRepositoryProvider).listDosesInRange(
        patientId: patient.id,
        rangeStart: _monthRangeStart(month),
        rangeEnd: _monthRangeEnd(month),
      );
});
