import 'package:donna_amparo/core/push/push_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolvePushNavigationTarget mapeia rotas conhecidas', () {
    expect(
      resolvePushNavigationTarget({'route': 'medicamentos'}),
      PushNavigationTarget.medicamentos,
    );
    expect(
      resolvePushNavigationTarget({'screen': '/alertas'}),
      PushNavigationTarget.alertas,
    );
    expect(
      resolvePushNavigationTarget({}),
      PushNavigationTarget.alertas,
    );
  });
}
