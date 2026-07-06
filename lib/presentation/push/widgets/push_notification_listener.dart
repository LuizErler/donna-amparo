import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_providers.dart';
import '../../care/providers/care_providers.dart';
import '../providers/push_providers.dart';

/// Sincroniza token FCM quando o cuidador autentica.
class PushNotificationListener extends ConsumerStatefulWidget {
  const PushNotificationListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<PushNotificationListener> createState() =>
      _PushNotificationListenerState();
}

class _PushNotificationListenerState
    extends ConsumerState<PushNotificationListener> {
  bool _syncInProgress = false;
  String? _syncedProfileId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIfNeeded());
  }

  Future<void> _syncIfNeeded() async {
    if (!ref.read(pushPlatformEnabledProvider)) return;

    final userId =
        supabase.auth.currentUser?.id ??
        ref.read(currentProfileProvider).valueOrNull?.id;
    if (userId == null) return;
    if (_syncInProgress || _syncedProfileId == userId) return;

    _syncInProgress = true;
    try {
      await initializePushNotifications(ref);
      await syncPushTokenForProfile(ref, profileId: userId);
      _syncedProfileId = userId;
    } catch (error, stackTrace) {
      debugPrint('Push sync falhou: $error');
      debugPrint('$stackTrace');
    } finally {
      _syncInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider, (previous, next) {
      next.whenData((isAuthenticated) async {
        if (!ref.read(pushPlatformEnabledProvider)) return;

        if (!isAuthenticated) {
          final profileId = _syncedProfileId ??
              ref.read(currentProfileProvider).valueOrNull?.id;
          if (profileId != null) {
            try {
              await unregisterPushTokenForProfile(ref, profileId: profileId);
            } catch (error) {
              debugPrint('Push unregister falhou: $error');
            }
          }
          _syncedProfileId = null;
          return;
        }

        await _syncIfNeeded();
      });
    });

    ref.listen(currentProfileProvider, (previous, next) {
      next.whenData((profile) {
        if (profile == null) return;
        if (_syncedProfileId == profile.id) return;
        _syncIfNeeded();
      });
    });

    return widget.child;
  }
}
