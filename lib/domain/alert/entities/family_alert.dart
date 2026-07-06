import 'package:flutter/material.dart';

import '../../notification/entities/notification_category.dart';

/// Alerta in-app exibido na aba Alertas (fonte derivada dos domínios).
class FamilyAlert {
  const FamilyAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.timeLabel,
    required this.occurredAt,
    required this.category,
    required this.resolved,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final String timeLabel;
  final DateTime occurredAt;
  final NotificationCategory category;
  final bool resolved;
  final IconData icon;

  String get filterLabel => category.filterLabel;
}
