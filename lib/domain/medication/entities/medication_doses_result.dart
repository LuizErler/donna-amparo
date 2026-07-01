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

  /// Primeira dose pendente (atrasada ou de hoje ainda nao confirmada).
  MedicationDose? get nextPendingDose {
    final pending = [
      ...overdue,
      ...today.where((d) => !d.taken && !d.isMarkedNotTaken),
    ];
    if (pending.isEmpty) return null;

    final sorted = List<MedicationDose>.from(pending)
      ..sort((a, b) {
        final dateCmp = a.scheduledFor.compareTo(b.scheduledFor);
        if (dateCmp != 0) return dateCmp;
        return a.timeLabel.compareTo(b.timeLabel);
      });
    return sorted.first;
  }
}
