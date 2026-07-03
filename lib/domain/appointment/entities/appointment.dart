import 'appointment_visit_type.dart';

/// Consulta ou exame agendado (`appointments`).
class Appointment {
  const Appointment({
    required this.id,
    this.title,
    this.doctor,
    this.specialty,
    this.location,
    this.appointmentDate,
    this.visitType,
    this.notes,
    this.reminder24h = false,
    this.notifyTeam = false,
  });

  final int id;
  final String? title;
  final String? doctor;
  final String? specialty;
  final String? location;
  final DateTime? appointmentDate;
  final String? visitType;
  final String? notes;
  final bool reminder24h;
  final bool notifyTeam;

  String get displaySpecialty => specialty?.trim().isNotEmpty == true
      ? specialty!.trim()
      : (title?.trim().isNotEmpty == true ? title!.trim() : 'Consulta');

  String get displayDoctor => doctor?.trim() ?? '';

  String get displayLocation => location?.trim() ?? '';

  String get visitTypeLabel =>
      AppointmentVisitType.fromCode(visitType).label;

  bool isUpcoming({DateTime? reference}) {
    final date = appointmentDate;
    if (date == null) return false;
    return !date.isBefore(reference ?? DateTime.now());
  }

  String get scheduleLabel {
    final local = appointmentDate?.toLocal();
    if (local == null) return '';
    final weekday = _weekdays[local.weekday - 1];
    final month = _months[local.month - 1];
    final day = local.day;
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$weekday, $day de $month · $h:$m';
  }

  String get historyLabel {
    final local = appointmentDate?.toLocal();
    if (local == null) return '';
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$day/$month · $h:$m';
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as int,
      title: json['title'] as String?,
      doctor: json['doctor'] as String?,
      specialty: json['specialty'] as String?,
      location: json['location'] as String?,
      appointmentDate: _parseDateTime(json['appointment_date'] as String?),
      visitType: json['visit_type'] as String?,
      notes: json['notes'] as String?,
      reminder24h: json['reminder_24h'] as bool? ?? false,
      notifyTeam: json['notify_team'] as bool? ?? false,
    );
  }

  static DateTime? _parseDateTime(String? raw) {
    if (raw == null) return null;
    return DateTime.parse(raw);
  }

  static const _weekdays = [
    'Segunda',
    'Terca',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sabado',
    'Domingo',
  ];

  static const _months = [
    'janeiro',
    'fevereiro',
    'marco',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
}
