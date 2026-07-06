import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../care/providers/care_providers.dart';
import '../../../core/supabase/supabase_config.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!ref.read(pushPlatformEnabledProvider)) return;
    await initializePushNotifications(ref);
    await _syncIfNeeded();
  }

  Future<void> _syncIfNeeded() async {
    final userId =
        supabase.auth.currentUser?.id ??
        ref.read(currentProfileProvider).valueOrNull?.id;
    if (userId == null) return;
    await syncPushTokenForProfile(ref, profileId: userId);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider, (previous, next) {
      next.whenData((isAuthenticated) async {
        if (!ref.read(pushPlatformEnabledProvider)) return;
        final profileId = ref.read(currentProfileProvider).valueOrNull?.id;
        if (!isAuthenticated) {
          if (profileId != null) {
            await unregisterPushTokenForProfile(ref, profileId: profileId);
          }
          return;
        }
        await initializePushNotifications(ref);
        await _syncIfNeeded();
      });
    });

    ref.listen(currentProfileProvider, (previous, next) {
      next.whenData((profile) async {
        if (profile == null) return;
        if (!ref.read(pushPlatformEnabledProvider)) return;
        await syncPushTokenForProfile(ref, profileId: profile.id);
      });
    });

    return widget.child;
  }
}
