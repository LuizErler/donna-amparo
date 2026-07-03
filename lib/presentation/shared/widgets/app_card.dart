import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Card padrao do design system (fundo, borda e raio consistentes).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.borderRadius = 16,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = color ?? AppTheme.cardSurface(context);
    final outlineColor = borderColor ?? AppTheme.cardOutline(context);

    return Container(
      width: width ?? double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: outlineColor),
      ),
      child: child,
    );
  }
}
