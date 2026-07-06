import '../../../domain/push/entities/device_token_platform.dart';
import '../../../domain/push/repositories/device_token_repository.dart';
import '../datasources/device_token_remote_datasource.dart';

class DeviceTokenRepositoryImpl implements DeviceTokenRepository {
  DeviceTokenRepositoryImpl(this._remote);

  final DeviceTokenRemoteDataSource _remote;

  @override
  Future<void> upsertToken({
    required String profileId,
    required String token,
    required DeviceTokenPlatform platform,
    String? appVersion,
  }) {
    return _remote.upsertToken(
      profileId: profileId,
      token: token,
      platform: platform,
      appVersion: appVersion,
    );
  }

  @override
  Future<void> deleteToken({
    required String profileId,
    required String token,
  }) {
    return _remote.deleteToken(profileId: profileId, token: token);
  }
}
