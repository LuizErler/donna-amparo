import 'package:flutter/material.dart';

/// Presets de frequencia diaria (Fase A — horarios fixos).
enum MedicationFrequencyPreset {
  onceDaily('1x ao dia', [
    TimeOfDay(hour: 8, minute: 0),
  ]),
  twiceDaily('2x ao dia', [
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 20, minute: 0),
  ]),
  threeTimesDaily('3x ao dia', [
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 20, minute: 0),
  ]),
  interval('A cada X horas', []),
  intervalDays('A cada X dias', []),
  custom('Personalizado', []);

  const MedicationFrequencyPreset(this.label, this.defaultTimes);

  final String label;
  final List<TimeOfDay> defaultTimes;
}
