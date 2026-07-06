import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/notification/entities/notification_category.dart';
import '../../domain/notification/entities/notification_preferences.dart';

const _prefsKey = 'notification_preferences_v1';

final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
  (ref) => NotificationPreferencesNotifier(),
);

class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferences> {
  NotificationPreferencesNotifier() : super(NotificationPreferences.defaults()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        state = NotificationPreferences.fromJson(decoded);
      }
    } catch (_) {
      // Mantém defaults se o JSON local estiver inválido.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  Future<void> setAlertEnabled(
    NotificationCategory category,
    bool enabled,
  ) async {
    final current = state.categories[category] ?? const CategoryPreference();
    state = state.updateCategory(
      category,
      current.copyWith(alertEnabled: enabled),
    );
    await _persist();
  }

  Future<void> setPushEnabled(
    NotificationCategory category,
    bool enabled,
  ) async {
    final current = state.categories[category] ?? const CategoryPreference();
    state = state.updateCategory(
      category,
      current.copyWith(pushEnabled: enabled),
    );
    await _persist();
  }
}
