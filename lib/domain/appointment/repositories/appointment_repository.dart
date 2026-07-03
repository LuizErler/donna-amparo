import '../entities/appointment.dart';
import '../entities/appointments_list_result.dart';
import '../entities/appointment_visit_type.dart';

class CreateAppointmentInput {
  const CreateAppointmentInput({
    required this.specialty,
    required this.appointmentDate,
    this.doctor,
    this.location,
    this.visitType = AppointmentVisitType.consulta,
    this.notes,
    this.reminder24h = true,
    this.notifyTeam = false,
  });

  final String specialty;
  final DateTime appointmentDate;
  final String? doctor;
  final String? location;
  final AppointmentVisitType visitType;
  final String? notes;
  final bool reminder24h;
  final bool notifyTeam;
}

abstract class AppointmentRepository {
  Future<AppointmentsListResult> listGrouped({
    required String patientId,
    DateTime? reference,
  });

  Future<List<Appointment>> listInRange({
    required String patientId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  });

  Future<void> createAppointment({
    required String patientId,
    required CreateAppointmentInput input,
  });
}
