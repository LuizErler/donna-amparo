import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'app_text_size';

enum AppTextSize {
  standard('Padrao', 1.0),
  large('Grande', 1.25);

  const AppTextSize(this.label, this.scale);

  final String label;
  final double scale;

  static AppTextSize fromName(String? value) {
    return AppTextSize.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppTextSize.standard,
    );
  }
}

final textSizeProvider =
    StateNotifierProvider<TextSizeNotifier, AppTextSize>((ref) {
  return TextSizeNotifier();
});

class TextSizeNotifier extends StateNotifier<AppTextSize> {
  TextSizeNotifier() : super(AppTextSize.standard) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppTextSize.fromName(prefs.getString(_prefsKey));
  }

  Future<void> setSize(AppTextSize size) async {
    state = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, size.name);
  }
}

/// Escala de texto aplicada globalmente (acessibilidade).
TextScaler appTextScaler(AppTextSize size) => TextScaler.linear(size.scale);
