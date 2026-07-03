import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'app_card.dart';

/// Estado vazio padrao com icone, titulo e mensagem opcionais.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.wrappedInCard = true,
    this.padding = const EdgeInsets.all(20),
  });

  final String message;
  final String? title;
  final IconData icon;
  final Widget? action;
  final bool wrappedInCard;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: AppTheme.onSurfaceSecondary(context)),
        if (title != null) ...[
          const SizedBox(height: 12),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (action != null) ...[
          const SizedBox(height: 16),
          action!,
        ],
      ],
    );

    if (!wrappedInCard) {
      return Padding(padding: padding, child: content);
    }

    return AppCard(padding: padding, child: content);
  }
}
