import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuração Firebase via `--dart-define` (sem commitar google-services.json).
///
/// Preencha em `dart_defines.local.json` ou rode `flutterfire configure` e
/// copie os valores para os defines abaixo.
class DefaultFirebaseOptions {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.example.meuApp',
  );

  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _messagingSenderId.isNotEmpty &&
      _projectId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
          'Push nao suportado nesta plataforma: $defaultTargetPlatform',
        ),
    };
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        iosBundleId: _iosBundleId,
      );

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
      );
}
