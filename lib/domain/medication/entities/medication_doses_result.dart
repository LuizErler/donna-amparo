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

  /// Doses que exigem atencao agora (atrasadas ou horario de hoje ja passou).
  List<MedicationDose> get attentionPendingDoses {
    final pending = [...overdue, ...today].where((d) => d.isDueNow).toList();
    pending.sort(_compareDoses);
    return pending;
  }

  /// Proxima dose que ja deveria ter sido tomada (ignora horarios futuros de hoje).
  MedicationDose? get nextPendingDose {
    final pending = attentionPendingDoses;
    return pending.isEmpty ? null : pending.first;
  }

  /// Todas as doses ainda nao confirmadas (inclui horarios futuros de hoje).
  List<MedicationDose> get scheduledPendingDoses {
    final pending = [
      ...overdue,
      ...today.where((d) => !d.taken && !d.isMarkedNotTaken),
    ];
    pending.sort(_compareDoses);
    return pending;
  }

  /// Proxima dose no radar (atrasada ou futura de hoje).
  MedicationDose? get nextScheduledDose {
    final pending = scheduledPendingDoses;
    return pending.isEmpty ? null : pending.first;
  }

  static int _compareDoses(MedicationDose a, MedicationDose b) {
    final dateCmp = a.scheduledFor.compareTo(b.scheduledFor);
    if (dateCmp != 0) return dateCmp;
    return a.timeLabel.compareTo(b.timeLabel);
  }
}
