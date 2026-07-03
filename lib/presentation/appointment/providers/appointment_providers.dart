import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/guarded_action.dart';
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

void _invalidateAppointmentViews(WidgetRef ref) {
  ref.invalidate(patientAppointmentsProvider);
  ref.invalidate(appointmentsInRangeProvider);
}

Future<String?> createAppointment(
  WidgetRef ref, {
  required String patientId,
  required CreateAppointmentInput input,
}) async {
  return runGuarded(
    () async {
      await ref.read(appointmentRepositoryProvider).createAppointment(
            patientId: patientId,
            input: input,
          );
      _invalidateAppointmentViews(ref);
    },
    fallback: 'Erro ao agendar consulta.',
  );
}

Future<String?> updateAppointment(
  WidgetRef ref, {
  required String patientId,
  required UpdateAppointmentInput input,
}) async {
  return runGuarded(
    () async {
      await ref.read(appointmentRepositoryProvider).updateAppointment(
            patientId: patientId,
            input: input,
          );
      _invalidateAppointmentViews(ref);
    },
    fallback: 'Erro ao atualizar consulta.',
  );
}

Future<String?> deleteAppointment(
  WidgetRef ref, {
  required String patientId,
  required int appointmentId,
}) async {
  return runGuarded(
    () async {
      await ref.read(appointmentRepositoryProvider).deleteAppointment(
            patientId: patientId,
            appointmentId: appointmentId,
          );
      _invalidateAppointmentViews(ref);
    },
    fallback: 'Erro ao cancelar consulta.',
  );
}
