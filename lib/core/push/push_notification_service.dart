import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_options.dart';

/// Handler de mensagens em background (top-level em main.dart reexporta isto).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService({
    required Future<void> Function({
      required String profileId,
      required String token,
      required String platform,
      String? appVersion,
    }) onRegisterToken,
    required Future<void> Function({
      required String profileId,
      required String token,
    }) onUnregisterToken,
    required void Function(RemoteMessage message) onMessageOpened,
  })  : _onRegisterToken = onRegisterToken,
        _onUnregisterToken = onUnregisterToken,
        _onMessageOpened = onMessageOpened;

  final Future<void> Function({
    required String profileId,
    required String token,
    required String platform,
    String? appVersion,
  }) _onRegisterToken;

  final Future<void> Function({
    required String profileId,
    required String token,
  }) _onUnregisterToken;

  final void Function(RemoteMessage message) _onMessageOpened;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  bool _initialized = false;
  String? _cachedToken;
  String? _activeProfileId;
  String? _appVersion;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  bool get isAvailable => DefaultFirebaseOptions.isConfigured && _initialized;

  Future<void> initialize() async {
    if (!DefaultFirebaseOptions.isConfigured || _initialized) return;
    if (kIsWeb) return;

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    _initialized = true;

    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_handleTokenRefresh);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _onMessageOpened(initial);
    }
  }

  Future<bool> requestPermission() async {
    if (!_initialized) return false;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> syncTokenForUser({
    required String profileId,
    String? appVersion,
  }) async {
    if (!_initialized) return;

    _activeProfileId = profileId;
    _appVersion = appVersion;

    final granted = await requestPermission();
    if (!granted) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    _cachedToken = token;
    await _onRegisterToken(
      profileId: profileId,
      token: token,
      platform: _platformCode,
      appVersion: appVersion,
    );
  }

  Future<void> unregisterForUser({required String profileId}) async {
    if (!_initialized) return;

    final token = _cachedToken ?? await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _onUnregisterToken(profileId: profileId, token: token);
    }

    await _messaging.deleteToken();
    _cachedToken = null;
    if (_activeProfileId == profileId) {
      _activeProfileId = null;
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _openedSub?.cancel();
    await _foregroundSub?.cancel();
  }

  Future<void> _handleTokenRefresh(String token) async {
    _cachedToken = token;
    final profileId = _activeProfileId;
    if (profileId == null) return;

    await _onRegisterToken(
      profileId: profileId,
      token: token,
      platform: _platformCode,
      appVersion: _appVersion,
    );
  }

  void _onForegroundMessage(RemoteMessage message) {
    // Fase 1: push em foreground fica para snackbar/deep link posterior.
  }

  String get _platformCode {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'web',
    };
  }
}
