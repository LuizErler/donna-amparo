import 'package:flutter/material.dart';

/// Periodo do dia para agrupamento na UI.
enum MedicationDayPeriod {
  dawn('Madrugada'),
  morning('Manhã'),
  afternoon('Tarde'),
  evening('Noite');

  const MedicationDayPeriod(this.label);

  final String label;

  /// Ordem cronologica na lista do dia (madrugada → manha → tarde → noite).
  static const displayOrder = [
    MedicationDayPeriod.dawn,
    MedicationDayPeriod.morning,
    MedicationDayPeriod.afternoon,
    MedicationDayPeriod.evening,
  ];

  IconData get icon => switch (this) {
        MedicationDayPeriod.dawn => Icons.bedtime_outlined,
        MedicationDayPeriod.morning => Icons.wb_sunny_outlined,
        MedicationDayPeriod.afternoon => Icons.wb_cloudy_outlined,
        MedicationDayPeriod.evening => Icons.nightlight_outlined,
      };

  static MedicationDayPeriod fromHour(int hour) {
    if (hour >= 0 && hour < 5) return MedicationDayPeriod.dawn;
    if (hour >= 5 && hour < 12) return MedicationDayPeriod.morning;
    if (hour >= 12 && hour < 18) return MedicationDayPeriod.afternoon;
    return MedicationDayPeriod.evening;
  }
}
