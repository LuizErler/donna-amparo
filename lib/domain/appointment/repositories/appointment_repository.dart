import '../entities/appointment.dart';
import '../entities/appointments_list_result.dart';
import '../entities/appointment_reminder_offset.dart';
import '../entities/appointment_visit_type.dart';

class CreateAppointmentInput {
  const CreateAppointmentInput({
    required this.specialty,
    required this.appointmentDate,
    this.doctor,
    this.location,
    this.visitType = AppointmentVisitType.consulta,
    this.notes,
    this.personalReminders = AppointmentReminderOffset.defaultPersonal,
    this.teamNotifyReminders = const [],
  });

  final String specialty;
  final DateTime appointmentDate;
  final String? doctor;
  final String? location;
  final AppointmentVisitType visitType;
  final String? notes;
  final List<AppointmentReminderOffset> personalReminders;
  final List<AppointmentReminderOffset> teamNotifyReminders;
}

class UpdateAppointmentInput {
  const UpdateAppointmentInput({
    required this.appointmentId,
    required this.specialty,
    required this.appointmentDate,
    this.doctor,
    this.location,
    this.visitType = AppointmentVisitType.consulta,
    this.notes,
    this.personalReminders = AppointmentReminderOffset.defaultPersonal,
    this.teamNotifyReminders = const [],
  });

  final int appointmentId;
  final String specialty;
  final DateTime appointmentDate;
  final String? doctor;
  final String? location;
  final AppointmentVisitType visitType;
  final String? notes;
  final List<AppointmentReminderOffset> personalReminders;
  final List<AppointmentReminderOffset> teamNotifyReminders;
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

  Future<void> updateAppointment({
    required String patientId,
    required UpdateAppointmentInput input,
  });

  Future<void> deleteAppointment({
    required String patientId,
    required int appointmentId,
  });
}
