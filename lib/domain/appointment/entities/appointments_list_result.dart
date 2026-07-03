import 'appointment.dart';

/// Consultas futuras e passadas para a tela de agenda.
class AppointmentsListResult {
  const AppointmentsListResult({
    required this.upcoming,
    required this.past,
  });

  final List<Appointment> upcoming;
  final List<Appointment> past;

  static const empty = AppointmentsListResult(upcoming: [], past: []);

  bool get isEmpty => upcoming.isEmpty && past.isEmpty;
}
