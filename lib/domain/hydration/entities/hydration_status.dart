import 'hydration_log.dart';

class HydrationStatus {
  const HydrationStatus({this.lastLog});

  static const attentionThreshold = Duration(hours: 2);

  final HydrationLog? lastLog;

  Duration? get timeSinceLast {
    final last = lastLog;
    if (last == null) return null;
    return DateTime.now().difference(last.recordedAt);
  }

  bool get needsAttention {
    final elapsed = timeSinceLast;
    if (elapsed == null) return true;
    return elapsed >= attentionThreshold;
  }

  String get elapsedLabel {
    final elapsed = timeSinceLast;
    if (elapsed == null) return 'Sem registros ainda';
    return _formatDuration(elapsed);
  }

  String messageForPatient(String patientName) {
    final elapsed = timeSinceLast;
    if (elapsed == null) {
      return 'Ainda não há registros de água para $patientName.';
    }
    if (needsAttention) {
      return 'Faz ${elapsedLabel.toLowerCase()} desde a última água. Hora de oferecer um copo ao $patientName.';
    }
    return 'Última hidratação registrada ${elapsedLabel.toLowerCase()}.';
  }

  static String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes;
    if (totalMinutes < 1) return 'Há menos de 1 min';
    if (totalMinutes < 60) return 'Há $totalMinutes min';

    final hours = duration.inHours;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return hours == 1 ? 'Há 1 hora' : 'Há $hours horas';
    }
    return 'Há ${hours}h ${minutes}min';
  }
}
