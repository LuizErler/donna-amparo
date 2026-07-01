import 'package:flutter/material.dart';

import '../../../domain/medication/entities/medication_dose.dart';
import '../../../domain/medication/entities/medication_doses_result.dart';
import '../../../domain/medication/entities/medication_schedule_mode.dart';
import '../../../domain/medication/entities/medication_summary.dart';
import '../../../domain/medication/repositories/medication_repository.dart';
import '../datasources/medication_remote_datasource.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  MedicationRepositoryImpl(this._remote);

  final MedicationRemoteDataSource _remote;

  @override
  Future<MedicationDosesResult> listDoses({
    required String patientId,
    required DateTime day,
    bool includeOverdue = true,
  }) {
    return _remote.listDoses(
      patientId: patientId,
      day: day,
      includeOverdue: includeOverdue,
    );
  }

  @override
  Future<List<MedicationDose>> listDosesInRange({
    required String patientId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    return _remote.listDosesInRange(
      patientId: patientId,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  @override
  Future<List<MedicationSummary>> listMedications({
    required String patientId,
    bool activeOnly = false,
  }) {
    return _remote.listMedications(
      patientId: patientId,
      activeOnly: activeOnly,
    );
  }

  @override
  Future<void> setDoseTaken({
    required String patientId,
    required int medicationId,
    required int? scheduleId,
    required String scheduledTime,
    required DateTime day,
    required bool taken,
  }) {
    return _remote.setDoseTaken(
      patientId: patientId,
      medicationId: medicationId,
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
      day: day,
      taken: taken,
    );
  }

  @override
  Future<void> createMedication({
    required String patientId,
    required CreateMedicationInput input,
  }) {
    return _remote.createMedication(
      patientId: patientId,
      name: input.name,
      dosage: input.dosage,
      instructions: input.instructions,
      scheduleTimes: _resolveScheduleTimes(input),
      startDate: input.startDate,
      endDate: input.endDate,
      scheduleMode: input.scheduleMode,
      intervalHours: input.intervalHours,
      anchorTime: _fmtTimeOpt(input.anchorTime),
    );
  }

  @override
  Future<void> updateMedication({
    required String patientId,
    required UpdateMedicationInput input,
  }) {
    return _remote.updateMedication(
      patientId: patientId,
      medicationId: input.medicationId,
      name: input.name,
      dosage: input.dosage,
      instructions: input.instructions,
      scheduleTimes: _resolveScheduleTimesFromUpdate(input),
      startDate: input.startDate,
      endDate: input.endDate,
      scheduleMode: input.scheduleMode,
      intervalHours: input.intervalHours,
      anchorTime: _fmtTimeOpt(input.anchorTime),
    );
  }

  @override
  Future<void> deactivateMedication({
    required String patientId,
    required int medicationId,
  }) {
    return _remote.deactivateMedication(
      patientId: patientId,
      medicationId: medicationId,
    );
  }

  @override
  Future<void> markDoseNotTaken({
    required String patientId,
    required int medicationId,
    required int? scheduleId,
    required String scheduledTime,
    required DateTime scheduledFor,
  }) {
    return _remote.markDoseNotTaken(
      patientId: patientId,
      medicationId: medicationId,
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
      scheduledFor: scheduledFor,
    );
  }

  List<String> _resolveScheduleTimes(CreateMedicationInput input) {
    if (input.scheduleMode == MedicationScheduleMode.interval) return [];
    return input.scheduleTimes.map(_fmtTime).toList();
  }

  List<String> _resolveScheduleTimesFromUpdate(UpdateMedicationInput input) {
    if (input.scheduleMode == MedicationScheduleMode.interval) return [];
    return input.scheduleTimes.map(_fmtTime).toList();
  }

  String _fmtTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  String? _fmtTimeOpt(TimeOfDay? time) {
    if (time == null) return null;
    return _fmtTime(time);
  }
}
