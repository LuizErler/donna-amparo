import 'medication_schedule_mode.dart';

/// Medicamento cadastrado (lista / edicao).
class MedicationSummary {
  const MedicationSummary({
    required this.id,
    required this.name,
    this.dosage,
    this.instructions,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.scheduleMode,
    this.intervalHours,
    this.intervalDays,
    this.anchorTime,
    this.anchorDate,
    required this.scheduleTimes,
  });

  final int id;
  final String name;
  final String? dosage;
  final String? instructions;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final MedicationScheduleMode scheduleMode;
  final int? intervalHours;
  final int? intervalDays;
  final String? anchorTime;
  final DateTime? anchorDate;
  final List<String> scheduleTimes;

  bool get isContinuous => endDate == null;

  String get frequencyLabel {
    if (scheduleMode == MedicationScheduleMode.intervalDays &&
        intervalDays != null) {
      return 'A cada $intervalDays dia${intervalDays == 1 ? '' : 's'}';
    }
    if (scheduleMode == MedicationScheduleMode.interval && intervalHours != null) {
      return 'A cada ${intervalHours}h';
    }
    final count = scheduleTimes.length;
    if (count == 1) return '1x ao dia';
    if (count == 2) return '2x ao dia';
    if (count == 3) return '3x ao dia';
    return '$count horarios';
  }

  String get periodLabel {
    if (!isActive) return 'Encerrado';
    if (isContinuous) return 'Uso continuo';
    if (startDate != null && endDate != null) {
      return 'ate ${_fmt(endDate!)}';
    }
    return 'Com prazo';
  }

  factory MedicationSummary.fromJson(Map<String, dynamic> json) {
    final schedules = json['medication_schedules'] as List<dynamic>? ?? [];
    final times = schedules
        .map((s) => (s as Map<String, dynamic>)['time_of_day'] as String)
        .toList()
      ..sort();

    return MedicationSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      dosage: json['dosage'] as String?,
      instructions: json['instructions'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      startDate: _parseDate(json['start_date'] as String?),
      endDate: _parseDate(json['end_date'] as String?),
      scheduleMode:
          MedicationScheduleMode.fromCode(json['schedule_mode'] as String?),
      intervalHours: json['interval_hours'] as int?,
      intervalDays: json['interval_days'] as int?,
      anchorTime: json['anchor_time'] as String?,
      anchorDate: _parseDate(json['anchor_date'] as String?),
      scheduleTimes: times,
    );
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    final d = DateTime.parse(raw);
    return DateTime(d.year, d.month, d.day);
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
