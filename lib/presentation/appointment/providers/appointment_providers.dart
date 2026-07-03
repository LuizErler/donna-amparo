import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/appointment/datasources/appointment_remote_datasource.dart';
import '../../../data/appointment/repositories/appointment_repository_impl.dart';
import '../../../domain/appointment/entities/appointment.dart';
import '../../../domain/appointment/entities/appointments_list_result.dart';
import '../../../domain/appointment/repositories/appointment_repository.dart';
import '../../care/providers/care_providers.dart';

final appointmentRemoteDataSourceProvider =
    Provider<AppointmentRemoteDataSource>((ref) {
  return AppointmentRemoteDataSource();
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepositoryImpl(ref.watch(appointmentRemoteDataSourceProvider));
});

/// Proximas e historico de consultas do paciente ativo.
final patientAppointmentsProvider =
    FutureProvider<AppointmentsListResult>((ref) async {
  ref.watch(authStateVersionProvider);

  final patient = await ref.watch(activePatientProvider.future);
  if (patient == null) return AppointmentsListResult.empty;

  return ref.watch(appointmentRepositoryProvider).listGrouped(
        patientId: patient.id,
      );
});

/// Consultas em um intervalo (para calendario / agregadores).
final appointmentsInRangeProvider = FutureProvider.family<
    List<Appointment>,
    ({DateTime start, DateTime end})>((ref, range) async {
  ref.watch(authStateVersionProvider);

  final patient = await ref.watch(activePatientProvider.future);
  if (patient == null) return [];

  return ref.watch(appointmentRepositoryProvider).listInRange(
        patientId: patient.id,
        rangeStart: range.start,
        rangeEnd: range.end,
      );
});
