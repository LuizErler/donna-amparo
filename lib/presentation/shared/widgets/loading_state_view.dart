import 'package:flutter/material.dart';

/// Indicador de carregamento padrao (tela cheia ou compacto inline).
class LoadingStateView extends StatelessWidget {
  const LoadingStateView({
    super.key,
    this.message,
    this.compact = false,
    this.indicatorColor,
    this.padding = const EdgeInsets.all(24),
  });

  final String? message;
  final bool compact;
  final Color? indicatorColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: compact ? 24 : 32,
      height: compact ? 24 : 32,
      child: CircularProgressIndicator(
        strokeWidth: compact ? 2 : 3,
        color: indicatorColor,
      ),
    );

    if (compact) return Center(child: indicator);

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            indicator,
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
