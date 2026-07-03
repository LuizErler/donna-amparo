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

  @override
  Future<void> createAppointment({
    required String patientId,
    required CreateAppointmentInput input,
  }) {
    return _remote.createAppointment(
      patientId: patientId,
      specialty: input.specialty.trim(),
      appointmentDate: input.appointmentDate,
      doctor: _trimOrNull(input.doctor),
      location: _trimOrNull(input.location),
      visitType: input.visitType.code,
      notes: _trimOrNull(input.notes),
      reminder24h: input.reminder24h,
      notifyTeam: input.notifyTeam,
    );
  }

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
