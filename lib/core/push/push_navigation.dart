import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aba principal a abrir após toque em notificação push.
enum PushNavigationTarget {
  home(0),
  medicamentos(1),
  consultas(2),
  calendario(3),
  alertas(4);

  const PushNavigationTarget(this.tabIndex);

  final int tabIndex;
}

final pushNavigationTargetProvider =
    StateProvider<PushNavigationTarget?>((ref) => null);

PushNavigationTarget? resolvePushNavigationTarget(Map<String, dynamic> data) {
  final route = data['route'] as String? ?? data['screen'] as String?;
  if (route == null) return PushNavigationTarget.alertas;

  return switch (route) {
    'home' || '/' => PushNavigationTarget.home,
    'medicamentos' || '/medicamentos' => PushNavigationTarget.medicamentos,
    'consultas' || '/consultas' => PushNavigationTarget.consultas,
    'calendario' || '/calendario' => PushNavigationTarget.calendario,
    'alertas' || '/alertas' => PushNavigationTarget.alertas,
    _ => PushNavigationTarget.alertas,
  };
}
