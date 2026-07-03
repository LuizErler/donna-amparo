import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/guarded_action.dart';
import '../../../data/medication/datasources/medication_remote_datasource.dart';
import '../../../data/medication/repositories/medication_repository_impl.dart';
import '../../../domain/medication/entities/medication_dose.dart';
import '../../../domain/medication/entities/medication_doses_result.dart';
import '../../../domain/medication/entities/medication_summary.dart';
import '../../../domain/medication/repositories/medication_repository.dart';
import '../../calendar/providers/calendar_providers.dart';
import '../../care/providers/care_providers.dart';

final medicationRemoteDataSourceProvider =
    Provider<MedicationRemoteDataSource>((ref) {
  return MedicationRemoteDataSource();
});

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepositoryImpl(ref.watch(medicationRemoteDataSourceProvider));
});

/// Doses de hoje + atrasadas para o paciente ativo.
final medicationDosesProvider =
    FutureProvider<MedicationDosesResult>((ref) async {
  ref.watch(authStateVersionProvider);

  final patient = await ref.watch(activePatientProvider.future);
  if (patient == null) {
    return const MedicationDosesResult(overdue: [], today: []);
  }

  return ref.watch(medicationRepositoryProvider).listDoses(
        patientId: patient.id,
        day: DateTime.now(),
      );
});

/// Lista de medicamentos cadastrados (ativos e encerrados).
final patientMedicationsProvider =
    FutureProvider<List<MedicationSummary>>((ref) async {
  ref.watch(authStateVersionProvider);

  final patient = await ref.watch(activePatientProvider.future);
  if (patient == null) return [];

  return ref.watch(medicationRepositoryProvider).listMedications(
        patientId: patient.id,
      );
});

void _invalidateMedicationViews(WidgetRef ref) {
  ref.invalidate(medicationDosesProvider);
  ref.invalidate(patientMedicationsProvider);
  ref.invalidate(medicationCalendarDosesProvider);
}

Future<String?> toggleMedicationDoseTaken(
  WidgetRef ref, {
  required int medicationId,
  required int? scheduleId,
  required String scheduledTime,
  required DateTime scheduledFor,
  required bool taken,
}) async {
  final patient = await ref.read(activePatientProvider.future);
  if (patient == null) return 'Paciente não encontrado.';

  return runGuarded(
    () async {
      await ref.read(medicationRepositoryProvider).setDoseTaken(
            patientId: patient.id,
            medicationId: medicationId,
            scheduleId: scheduleId,
            scheduledTime: scheduledTime,
            day: scheduledFor,
            taken: taken,
          );
      _invalidateMedicationViews(ref);
    },
    fallback: 'Erro ao atualizar dose.',
  );
}

Future<String?> createMedication(
  WidgetRef ref, {
  required String patientId,
  required CreateMedicationInput input,
}) async {
  return runGuarded(
    () async {
      await ref.read(medicationRepositoryProvider).createMedication(
            patientId: patientId,
            input: input,
          );
      _invalidateMedicationViews(ref);
    },
    fallback: 'Erro ao cadastrar medicamento.',
  );
}

Future<String?> updateMedication(
  WidgetRef ref, {
  required String patientId,
  required UpdateMedicationInput input,
}) async {
  return runGuarded(
    () async {
      await ref.read(medicationRepositoryProvider).updateMedication(
            patientId: patientId,
            input: input,
          );
      _invalidateMedicationViews(ref);
    },
    fallback: 'Erro ao atualizar medicamento.',
  );
}

Future<String?> deactivateMedication(
  WidgetRef ref, {
  required String patientId,
  required int medicationId,
}) async {
  return runGuarded(
    () async {
      await ref.read(medicationRepositoryProvider).deactivateMedication(
            patientId: patientId,
            medicationId: medicationId,
          );
      _invalidateMedicationViews(ref);
    },
    fallback: 'Erro ao encerrar medicamento.',
  );
}

Future<String?> markDoseNotTaken(
  WidgetRef ref, {
  required MedicationDose dose,
}) async {
  final patient = await ref.read(activePatientProvider.future);
  if (patient == null) return 'Paciente não encontrado.';

  return runGuarded(
    () async {
      await ref.read(medicationRepositoryProvider).markDoseNotTaken(
            patientId: patient.id,
            medicationId: dose.medicationId,
            scheduleId: dose.scheduleId > 0 ? dose.scheduleId : null,
            scheduledTime: dose.scheduledTime,
            scheduledFor: dose.scheduledFor,
          );
      _invalidateMedicationViews(ref);
    },
    fallback: 'Erro ao registrar dose não tomada.',
  );
}

Future<String?> resolveAllOverdueDoses(
  WidgetRef ref, {
  required List<MedicationDose> overdue,
}) async {
  for (final dose in overdue) {
    final error = await markDoseNotTaken(ref, dose: dose);
    if (error != null) return error;
  }
  return null;
}
