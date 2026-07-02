import 'package:flutter/material.dart';

/// Estado de erro padrao com icone e mensagem.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.error_outline,
    this.padding = const EdgeInsets.all(24),
    this.centered = true,
    this.alignStart = false,
  });

  final String message;
  final String? title;
  final IconData icon;
  final EdgeInsetsGeometry padding;
  final bool centered;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        if (centered)
          Icon(
            icon,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          )
        else
          Icon(
            icon,
            size: 28,
            color: Theme.of(context).colorScheme.error,
          ),
        if (centered) const SizedBox(height: 16),
        if (title != null) ...[
          Text(
            title!,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: alignStart ? TextAlign.start : TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        Text(
          message,
          textAlign: alignStart ? TextAlign.start : TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );

    return Padding(
      padding: padding,
      child: centered
          ? Center(child: content)
          : content,
    );
  }
}
