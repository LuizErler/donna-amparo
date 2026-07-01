import 'package:flutter/material.dart';

/// Garante area minima de toque de 48x48 (WCAG / Material).
/// Nao usar dentro de [InputDecoration.suffixIcon] — prefira [IconButton].
class MinTapTarget extends StatelessWidget {
  const MinTapTarget({
    super.key,
    required this.child,
    this.semanticsLabel,
    this.onTap,
  });

  final Widget child;
  final String? semanticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final target = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Center(child: child),
    );

    if (semanticsLabel == null && onTap == null) return target;

    return Semantics(
      button: onTap != null,
      label: semanticsLabel,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: target,
            )
          : target,
    );
  }
}
