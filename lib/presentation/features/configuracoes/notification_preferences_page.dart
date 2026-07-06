import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/notification_preferences_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/notification/entities/notification_category.dart';
import '../../../domain/notification/entities/notification_preferences.dart';
import '../../push/providers/push_providers.dart';

class NotificationPreferencesPage extends ConsumerWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(notificationPreferencesProvider);
    final pushConfigured = ref.watch(pushPlatformEnabledProvider);
    final cardColor = AppTheme.cardSurface(context);
    final borderColor = AppTheme.cardOutline(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroCard(context, cardColor, borderColor),
            const SizedBox(height: 28),
            _buildSectionHeader(
              context,
              title: 'Alertas no app',
              subtitle:
                  'O que aparece na aba Alertas, dentro do Donna Amparo.',
            ),
            const SizedBox(height: 12),
            _buildPreferenceCard(
              context,
              cardColor: cardColor,
              borderColor: borderColor,
              preferences: preferences,
              enabledFor: (category) => preferences.isAlertEnabled(category),
              onChanged: (category, enabled) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .setAlertEnabled(category, enabled),
            ),
            const SizedBox(height: 28),
            _buildSectionHeader(
              context,
              title: 'Notificações no celular',
              subtitle:
                  'Avisos push quando o app está fechado ou em segundo plano.',
            ),
            const SizedBox(height: 12),
            if (!pushConfigured)
              _buildPushInfoBanner(context, cardColor, borderColor),
            if (!pushConfigured) const SizedBox(height: 12),
            _buildPreferenceCard(
              context,
              cardColor: cardColor,
              borderColor: borderColor,
              preferences: preferences,
              enabledFor: (category) => preferences.isPushEnabled(category),
              onChanged: (category, enabled) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .setPushEnabled(category, enabled),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(
    BuildContext context,
    Color cardColor,
    Color borderColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Como funciona',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Alertas ficam na aba Alertas do app. Notificações são os avisos '
            'push no celular — gerados pelos mesmos eventos, mas entregues '
            'fora do app.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildPushInfoBanner(
    BuildContext context,
    Color cardColor,
    Color borderColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.phonelink_ring_outlined, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Configure o Firebase no app para ativar push. '
              'Suas preferências já ficam salvas neste aparelho.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard(
    BuildContext context, {
    required Color cardColor,
    required Color borderColor,
    required NotificationPreferences preferences,
    required bool Function(NotificationCategory category) enabledFor,
    required Future<void> Function(NotificationCategory category, bool enabled)
        onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          for (var i = 0; i < NotificationCategory.values.length; i++) ...[
            if (i > 0) Divider(height: 1, color: borderColor),
            _buildToggleRow(
              context,
              category: NotificationCategory.values[i],
              value: enabledFor(NotificationCategory.values[i]),
              onChanged: (value) =>
                  onChanged(NotificationCategory.values[i], value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    BuildContext context, {
    required NotificationCategory category,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(category.icon, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.label,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(category.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
