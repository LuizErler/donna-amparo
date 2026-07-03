import 'package:flutter/material.dart';

import '../entities/medication_dose.dart';
import '../entities/medication_doses_result.dart';
import '../entities/medication_schedule_mode.dart';
import '../entities/medication_summary.dart';

enum MedicationTreatmentType {
  continuous('Uso contínuo'),
  limited('Tratamento com prazo');

  const MedicationTreatmentType(this.label);

  final String label;
}

class CreateMedicationInput {
  const CreateMedicationInput({
    required this.name,
    this.dosage,
    this.instructions,
    required this.scheduleTimes,
    required this.startDate,
    this.endDate,
    this.scheduleMode = MedicationScheduleMode.fixedTimes,
    this.intervalHours,
    this.intervalDays,
    this.anchorTime,
    this.anchorDate,
  });

  final String name;
  final String? dosage;
  final String? instructions;
  final List<TimeOfDay> scheduleTimes;
  final DateTime startDate;
  final DateTime? endDate;
  final MedicationScheduleMode scheduleMode;
  final int? intervalHours;
  final int? intervalDays;
  final TimeOfDay? anchorTime;
  final DateTime? anchorDate;
}

class UpdateMedicationInput {
  const UpdateMedicationInput({
    required this.medicationId,
    required this.name,
    this.dosage,
    this.instructions,
    required this.scheduleTimes,
    required this.startDate,
    this.endDate,
    this.scheduleMode = MedicationScheduleMode.fixedTimes,
    this.intervalHours,
    this.intervalDays,
    this.anchorTime,
    this.anchorDate,
  });

  final int medicationId;
  final String name;
  final String? dosage;
  final String? instructions;
  final List<TimeOfDay> scheduleTimes;
  final DateTime startDate;
  final DateTime? endDate;
  final MedicationScheduleMode scheduleMode;
  final int? intervalHours;
  final int? intervalDays;
  final TimeOfDay? anchorTime;
  final DateTime? anchorDate;
}

abstract class MedicationRepository {
  Future<MedicationDosesResult> listDoses({
    required String patientId,
    required DateTime day,
    bool includeOverdue = true,
  });

  Future<List<MedicationDose>> listDosesInRange({
    required String patientId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  });

  Future<List<MedicationSummary>> listMedications({
    required String patientId,
    bool activeOnly = false,
  });

  Future<void> setDoseTaken({
    required String patientId,
    required int medicationId,
    required int? scheduleId,
    required String scheduledTime,
    required DateTime day,
    required bool taken,
  });

  Future<void> createMedication({
    required String patientId,
    required CreateMedicationInput input,
  });

  Future<void> updateMedication({
    required String patientId,
    required UpdateMedicationInput input,
  });

  Future<void> deactivateMedication({
    required String patientId,
    required int medicationId,
  });

  Future<void> markDoseNotTaken({
    required String patientId,
    required int medicationId,
    required int? scheduleId,
    required String scheduledTime,
    required DateTime scheduledFor,
  });
}
