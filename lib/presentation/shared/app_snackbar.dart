import 'package:flutter/material.dart';

import '../../core/errors/error_message_mapper.dart';

enum AppSnackVariant { info, success, error }

/// Snackbar padronizado do app (floating, cores por variante).
void showAppSnack(
  BuildContext context,
  String message, {
  AppSnackVariant variant = AppSnackVariant.info,
}) {
  final backgroundColor = switch (variant) {
    AppSnackVariant.error => Colors.red.shade700,
    AppSnackVariant.success => null,
    AppSnackVariant.info => null,
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

void showAppErrorSnack(
  BuildContext context,
  Object error, {
  String fallback = 'Ocorreu um erro inesperado. Tente novamente.',
}) {
  showAppSnack(
    context,
    mapErrorMessage(error, fallback: fallback),
    variant: AppSnackVariant.error,
  );
}

void showAppSuccessSnack(BuildContext context, String message) {
  showAppSnack(context, message, variant: AppSnackVariant.success);
}
