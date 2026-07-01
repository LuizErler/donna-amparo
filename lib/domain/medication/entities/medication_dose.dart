import 'medication_day_period.dart';
import 'medication_skipped_reason.dart';

/// Dose com status de confirmacao (view model para a lista).
class MedicationDose {
  const MedicationDose({
    required this.medicationId,
    required this.scheduleId,
    required this.name,
    required this.instructions,
    required this.timeLabel,
    required this.scheduledTime,
    required this.scheduledFor,
    required this.period,
    required this.taken,
    required this.isOverdue,
    this.logId,
    this.dosage,
    this.skippedReason,
  });

  final int medicationId;
  final int scheduleId;
  final String name;
  final String? dosage;
  final String instructions;
  final String timeLabel;
  final String scheduledTime;
  final DateTime scheduledFor;
  final MedicationDayPeriod period;
  final bool taken;
  final bool isOverdue;
  final String? logId;
  final String? skippedReason;

  bool get isMarkedNotTaken =>
      skippedReason == MedicationSkippedReason.notTaken;

  String get displayName {
    final dose = dosage?.trim();
    if (dose == null || dose.isEmpty) return name;
    return '$name $dose';
  }

  String get overdueLabel {
    if (!isOverdue) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(scheduledFor).inDays;
    if (diff == 1) return 'Ontem';
    if (diff > 1) return 'Ha $diff dias';
    return 'Atrasada';
  }

  factory MedicationDose.fromJson(
    Map<String, dynamic> json, {
    required DateTime scheduledFor,
    required DateTime referenceDay,
  }) {
    final medication = json['medications'] as Map<String, dynamic>? ?? json;
    final schedule = json['medication_schedules'] as Map<String, dynamic>?;
    final log = _firstLog(json['medication_logs']);

    final timeRaw = schedule?['time_of_day'] as String? ??
        json['scheduled_time'] as String? ??
        '00:00:00';
    final parts = timeRaw.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final timeLabel =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    final taken = log?['taken'] as bool? ?? false;
    final skippedReason = log?['skipped_reason'] as String?;
    final scheduledDate = DateTime(
      scheduledFor.year,
      scheduledFor.month,
      scheduledFor.day,
    );
    final refDate = DateTime(
      referenceDay.year,
      referenceDay.month,
      referenceDay.day,
    );
    final isOverdue = scheduledDate.isBefore(refDate) &&
        !taken &&
        skippedReason == null;

    return MedicationDose(
      medicationId: medication['id'] as int,
      scheduleId: schedule?['id'] as int? ?? 0,
      name: medication['name'] as String,
      dosage: medication['dosage'] as String?,
      instructions: medication['instructions'] as String? ?? '',
      timeLabel: timeLabel,
      scheduledTime: timeRaw,
      scheduledFor: scheduledDate,
      period: MedicationDayPeriod.fromHour(hour),
      taken: taken,
      isOverdue: isOverdue,
      logId: log?['id'] as String?,
      skippedReason: skippedReason,
    );
  }

  static Map<String, dynamic>? _firstLog(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map<String, dynamic>) return first;
    }
    return null;
  }
}
