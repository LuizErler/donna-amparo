import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donna_amparo/presentation/auth/screens/login_screen.dart';

void main() {
  testWidgets('Login exibe titulo e botao Entrar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Bem-vinda de volta'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
