import '../entities/appointment.dart';
import '../entities/appointments_list_result.dart';

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
}
