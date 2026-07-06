import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_options.dart';
import '../../../core/push/push_navigation.dart';
import '../../../core/push/push_notification_service.dart';
import '../../../data/push/datasources/device_token_remote_datasource.dart';
import '../../../data/push/repositories/device_token_repository_impl.dart';
import '../../../domain/push/entities/device_token_platform.dart';
import '../../../domain/push/repositories/device_token_repository.dart';

final deviceTokenRemoteDataSourceProvider =
    Provider<DeviceTokenRemoteDataSource>((ref) {
  return DeviceTokenRemoteDataSource();
});

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  return DeviceTokenRepositoryImpl(ref.watch(deviceTokenRemoteDataSourceProvider));
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final repository = ref.watch(deviceTokenRepositoryProvider);

  final service = PushNotificationService(
    onRegisterToken: ({
      required String profileId,
      required String token,
      required String platform,
      String? appVersion,
    }) {
      return repository.upsertToken(
        profileId: profileId,
        token: token,
        platform: DeviceTokenPlatform.values.firstWhere(
          (p) => p.code == platform,
          orElse: () => DeviceTokenPlatform.android,
        ),
        appVersion: appVersion,
      );
    },
    onUnregisterToken: ({
      required String profileId,
      required String token,
    }) {
      return repository.deleteToken(profileId: profileId, token: token);
    },
    onMessageOpened: (message) {
      final target = resolvePushNavigationTarget(message.data);
      if (target != null) {
        ref.read(pushNavigationTargetProvider.notifier).state = target;
      }
    },
  );

  ref.onDispose(service.dispose);
  return service;
});

final pushPlatformEnabledProvider = Provider<bool>((ref) {
  return DefaultFirebaseOptions.isConfigured;
});

Future<void> initializePushNotifications(WidgetRef ref) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  await ref.read(pushNotificationServiceProvider).initialize();
}

Future<void> syncPushTokenForProfile(
  WidgetRef ref, {
  required String profileId,
}) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  await ref.read(pushNotificationServiceProvider).syncTokenForUser(
        profileId: profileId,
      );
}

Future<void> unregisterPushTokenForProfile(
  WidgetRef ref, {
  required String profileId,
}) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  await ref.read(pushNotificationServiceProvider).unregisterForUser(
        profileId: profileId,
      );
}
