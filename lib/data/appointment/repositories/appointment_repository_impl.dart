import '../../../domain/appointment/entities/appointment.dart';
import '../../../domain/appointment/entities/appointments_list_result.dart';
import '../../../domain/appointment/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_datasource.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl(this._remote);

  final AppointmentRemoteDataSource _remote;

  @override
  Future<AppointmentsListResult> listGrouped({
    required String patientId,
    DateTime? reference,
  }) async {
    final now = reference ?? DateTime.now();
    final all = await _remote.listAppointments(patientId: patientId);

    final upcoming = <Appointment>[];
    final past = <Appointment>[];

    for (final appointment in all) {
      if (appointment.isUpcoming(reference: now)) {
        upcoming.add(appointment);
      } else {
        past.add(appointment);
      }
    }

    upcoming.sort(
      (a, b) => (a.appointmentDate ?? DateTime(0))
          .compareTo(b.appointmentDate ?? DateTime(0)),
    );
    past.sort(
      (a, b) => (b.appointmentDate ?? DateTime(0))
          .compareTo(a.appointmentDate ?? DateTime(0)),
    );

    return AppointmentsListResult(upcoming: upcoming, past: past);
  }

  @override
  Future<List<Appointment>> listInRange({
    required String patientId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    return _remote.listAppointmentsInRange(
      patientId: patientId,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }
}
