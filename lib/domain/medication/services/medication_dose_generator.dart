import '../entities/medication_dose.dart';
import '../entities/medication_doses_result.dart';
import '../entities/medication_schedule_mode.dart';
import '../entities/medication_treatment_period.dart';

class _Slot {
  const _Slot({required this.scheduleId, required this.timeOfDay});

  final int scheduleId;
  final String timeOfDay;
}

/// Gera slots de dose (fixos ou por intervalo) para um dia civil.
class MedicationDoseGenerator {
  MedicationDoseGenerator._();

  static const overdueLookbackDays = 3;

  static MedicationDosesResult buildResult({
    required List<Map<String, dynamic>> medications,
    required Map<String, Map<String, dynamic>> logsByKey,
    required DateTime today,
    required bool includeOverdue,
  }) {
    final todayDate = _dateOnly(today);
    final overdue = <MedicationDose>[];
    final todayDoses = <MedicationDose>[];

    final lookbackStart = includeOverdue
        ? todayDate.subtract(const Duration(days: overdueLookbackDays))
        : todayDate;

    for (var day = lookbackStart;
        !day.isAfter(todayDate);
        day = day.add(const Duration(days: 1))) {
      final isToday = day == todayDate;

      for (final med in medications) {
        if (!_isMedActiveOnDay(med, day)) continue;

        final slots = _slotsForDay(med, day);
        for (final slot in slots) {
          final logKey =
              '${med['id']}:${_formatDate(day)}:${slot.timeOfDay}';
          final log = logsByKey[logKey];
          final dose = MedicationDose.fromJson(
            {
              'medications': med,
              'medication_schedules': slot.scheduleId > 0
                  ? {'id': slot.scheduleId, 'time_of_day': slot.timeOfDay}
                  : null,
              'medication_logs': log,
              'scheduled_time': slot.timeOfDay,
            },
            scheduledFor: day,
            referenceDay: todayDate,
          );

          if (isToday) {
            todayDoses.add(dose);
          } else if (dose.isOverdue) {
            overdue.add(dose);
          }
        }
      }
    }

    int compareDoses(MedicationDose a, MedicationDose b) {
      final dateCmp = a.scheduledFor.compareTo(b.scheduledFor);
      if (dateCmp != 0) return dateCmp;
      return a.timeLabel.compareTo(b.timeLabel);
    }

    overdue.sort(compareDoses);
    todayDoses.sort((a, b) => a.timeLabel.compareTo(b.timeLabel));
    return MedicationDosesResult(overdue: overdue, today: todayDoses);
  }

  /// Doses de um unico dia civil (para calendario e agregadores).
  static List<MedicationDose> dosesForDay({
    required List<Map<String, dynamic>> medications,
    required Map<String, Map<String, dynamic>> logsByKey,
    required DateTime day,
    DateTime? referenceDay,
  }) {
    final dayDate = _dateOnly(day);
    final refDate = _dateOnly(referenceDay ?? DateTime.now());
    final doses = <MedicationDose>[];

    for (final med in medications) {
      if (!_isMedActiveOnDay(med, dayDate)) continue;

      final slots = _slotsForDay(med, dayDate);
      for (final slot in slots) {
        final logKey =
            '${med['id']}:${_formatDate(dayDate)}:${slot.timeOfDay}';
        final log = logsByKey[logKey];
        doses.add(
          MedicationDose.fromJson(
            {
              'medications': med,
              'medication_schedules': slot.scheduleId > 0
                  ? {'id': slot.scheduleId, 'time_of_day': slot.timeOfDay}
                  : null,
              'medication_logs': log,
              'scheduled_time': slot.timeOfDay,
            },
            scheduledFor: dayDate,
            referenceDay: refDate,
          ),
        );
      }
    }

    doses.sort((a, b) => a.timeLabel.compareTo(b.timeLabel));
    return doses;
  }

  /// Doses em um intervalo de dias (inclusive).
  static List<MedicationDose> dosesForRange({
    required List<Map<String, dynamic>> medications,
    required Map<String, Map<String, dynamic>> logsByKey,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    DateTime? referenceDay,
  }) {
    final start = _dateOnly(rangeStart);
    final end = _dateOnly(rangeEnd);
    final doses = <MedicationDose>[];

    for (var day = start;
        !day.isAfter(end);
        day = day.add(const Duration(days: 1))) {
      doses.addAll(
        dosesForDay(
          medications: medications,
          logsByKey: logsByKey,
          day: day,
          referenceDay: referenceDay,
        ),
      );
    }

    return doses;
  }

  /// Preview de slots para cadastro (proximos dias).
  static List<String> previewLabels({
    required MedicationScheduleMode scheduleMode,
    required DateTime startDate,
    DateTime? endDate,
    required List<String> scheduleTimes,
    int? intervalHours,
    String? anchorTime,
    int? intervalDays,
    String? anchorDate,
    int previewDays = 3,
  }) {
    final med = <String, dynamic>{
      'id': 0,
      'name': '',
      'start_date': _formatDate(startDate),
      'end_date': endDate != null ? _formatDate(endDate) : null,
      'schedule_mode': scheduleMode.code,
      'interval_hours': intervalHours,
      'anchor_time': anchorTime,
      'interval_days': intervalDays,
      'anchor_date': anchorDate,
      'medication_schedules': scheduleTimes
          .map((t) => {'id': 0, 'time_of_day': t})
          .toList(),
    };

    final labels = <String>[];
    final lastDay = startDate.add(Duration(days: previewDays - 1));
    final cap =
        endDate != null && endDate.isBefore(lastDay) ? endDate : lastDay;

    for (var day = _dateOnly(startDate);
        !day.isAfter(cap);
        day = day.add(const Duration(days: 1))) {
      if (!_isMedActiveOnDay(med, day)) continue;
      final slots = _slotsForDay(med, day);
      if (slots.isEmpty) continue;
      final times = slots.map((s) => _formatTimeLabel(s.timeOfDay)).join(', ');
      labels.add('${_formatDateBr(day)}: $times');
    }
    return labels;
  }

  static List<_Slot> _slotsForDay(Map<String, dynamic> med, DateTime day) {
    final mode =
        MedicationScheduleMode.fromCode(med['schedule_mode'] as String?);
    if (mode == MedicationScheduleMode.interval) {
      return _intervalHoursSlots(med, day);
    }
    if (mode == MedicationScheduleMode.intervalDays) {
      return _intervalDaysSlots(med, day);
    }
    return _fixedSlots(med, day);
  }

  static List<_Slot> _fixedSlots(Map<String, dynamic> med, DateTime day) {
    final schedules = med['medication_schedules'] as List<dynamic>? ?? [];
    return schedules.map((raw) {
      final schedule = raw as Map<String, dynamic>;
      return _Slot(
        scheduleId: schedule['id'] as int? ?? 0,
        timeOfDay: schedule['time_of_day'] as String,
      );
    }).toList();
  }

  static List<_Slot> _intervalHoursSlots(Map<String, dynamic> med, DateTime day) {
    final intervalHours = med['interval_hours'] as int?;
    final anchorRaw = med['anchor_time'] as String?;
    final startStr = med['start_date'] as String?;
    if (intervalHours == null || intervalHours < 1 || anchorRaw == null) {
      return [];
    }

    final anchorParts = anchorRaw.split(':');
    final anchorHour = int.tryParse(anchorParts.first) ?? 0;
    final anchorMinute =
        anchorParts.length > 1 ? int.tryParse(anchorParts[1]) ?? 0 : 0;

    final treatmentStart =
        startStr != null ? DateTime.parse(startStr) : day;
    final treatmentStartDt = DateTime(
      treatmentStart.year,
      treatmentStart.month,
      treatmentStart.day,
      anchorHour,
      anchorMinute,
    );

    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    var cursor = treatmentStartDt;
    if (cursor.isBefore(dayStart)) {
      final minutesDiff = dayStart.difference(cursor).inMinutes;
      final intervalMinutes = intervalHours * 60;
      final steps = (minutesDiff / intervalMinutes).ceil();
      cursor = treatmentStartDt
          .add(Duration(minutes: steps * intervalMinutes));
    }

    final slots = <_Slot>[];
    while (cursor.isBefore(dayEnd)) {
      if (!cursor.isBefore(dayStart) && _isMedActiveOnDay(med, cursor)) {
        slots.add(_Slot(
          scheduleId: 0,
          timeOfDay:
              '${cursor.hour.toString().padLeft(2, '0')}:${cursor.minute.toString().padLeft(2, '0')}:00',
        ));
      }
      cursor = cursor.add(Duration(hours: intervalHours));
    }
    return slots;
  }

  static List<_Slot> _intervalDaysSlots(Map<String, dynamic> med, DateTime day) {
    final intervalDays = med['interval_days'] as int?;
    final anchorDateRaw = med['anchor_date'] as String?;
    final anchorTimeRaw = med['anchor_time'] as String?;
    if (intervalDays == null ||
        intervalDays < 1 ||
        anchorDateRaw == null ||
        anchorTimeRaw == null) {
      return [];
    }

    final anchorDay = _dateOnly(DateTime.parse(anchorDateRaw));
    final targetDay = _dateOnly(day);
    if (targetDay.isBefore(anchorDay)) return [];

    final diffDays = targetDay.difference(anchorDay).inDays;
    if (diffDays % intervalDays != 0) return [];

    return [
      _Slot(
        scheduleId: 0,
        timeOfDay: _normalizeTimeOfDay(anchorTimeRaw),
      ),
    ];
  }

  static String _normalizeTimeOfDay(String raw) {
    final parts = raw.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
    }
    return raw;
  }

  static bool _isMedActiveOnDay(Map<String, dynamic> med, DateTime day) {
    DateTime? start;
    DateTime? end;
    final startStr = med['start_date'] as String?;
    final endStr = med['end_date'] as String?;
    if (startStr != null) start = DateTime.parse(startStr);
    if (endStr != null) end = DateTime.parse(endStr);
    return MedicationTreatmentPeriod.isActiveOnDay(
      day: day,
      startDate: start,
      endDate: end,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _formatDateBr(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  static String _formatTimeLabel(String timeRaw) {
    final parts = timeRaw.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
