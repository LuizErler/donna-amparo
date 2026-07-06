import 'package:flutter/material.dart';

/// Categorias de alertas e notificações configuráveis pelo cuidador.
enum NotificationCategory {
  medications(
    label: 'Medicamentos',
    filterLabel: 'Medicamentos',
    subtitle: 'Doses pendentes, atrasadas e confirmações',
    icon: Icons.medication_outlined,
  ),
  appointments(
    label: 'Consultas e exames',
    filterLabel: 'Consultas',
    subtitle: 'Lembretes de agenda e avisos à família',
    icon: Icons.calendar_today_outlined,
  ),
  hydration(
    label: 'Hidratação',
    filterLabel: 'Hidratação',
    subtitle: 'Lembretes quando a ingestão de água atrasa',
    icon: Icons.water_drop_outlined,
  ),
  vitals(
    label: 'Vitais',
    filterLabel: 'Vitais',
    subtitle: 'Pressão, glicemia e outros sinais registrados',
    icon: Icons.monitor_heart_outlined,
  ),
  family(
    label: 'Família',
    filterLabel: 'Família',
    subtitle: 'Convites, papéis e movimentações do círculo',
    icon: Icons.people_outline,
  );

  const NotificationCategory({
    required this.label,
    required this.filterLabel,
    required this.subtitle,
    required this.icon,
  });

  final String label;
  final String filterLabel;
  final String subtitle;
  final IconData icon;

  static NotificationCategory? fromFilterLabel(String label) {
    for (final category in values) {
      if (category.filterLabel == label) return category;
    }
    return null;
  }
}
