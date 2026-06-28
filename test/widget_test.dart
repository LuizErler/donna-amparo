import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donna_amparo/app.dart';

void main() {
  testWidgets('App exibe tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DonnaAmparoApp(),
      ),
    );

    expect(find.text('Bem-vinda de volta'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
