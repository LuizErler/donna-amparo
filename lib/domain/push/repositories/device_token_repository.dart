import '../entities/device_token_platform.dart';

abstract class DeviceTokenRepository {
  Future<void> upsertToken({
    required String profileId,
    required String token,
    required DeviceTokenPlatform platform,
    String? appVersion,
  });

  Future<void> deleteToken({
    required String profileId,
    required String token,
  });
}
