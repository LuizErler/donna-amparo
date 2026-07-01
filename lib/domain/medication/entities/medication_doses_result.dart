import 'medication_dose.dart';

class MedicationDosesResult {
  const MedicationDosesResult({
    required this.overdue,
    required this.today,
  });

  final List<MedicationDose> overdue;
  final List<MedicationDose> today;

  bool get isEmpty => overdue.isEmpty && today.isEmpty;
  int get totalToday => today.length;
  int get takenToday => today.where((d) => d.taken).length;
}
