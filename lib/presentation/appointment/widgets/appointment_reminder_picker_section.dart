import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/appointment/entities/appointment_reminder_offset.dart';

/// Lista expansivel de alertas com picker estilo Calendario iOS.
class AppointmentReminderPickerSection extends StatelessWidget {
  const AppointmentReminderPickerSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.offsets,
    required this.enabled,
    required this.onChanged,
    this.notifyFamily = false,
    this.onNotifyFamilyChanged,
    this.familyToggleTitle = 'Avisar a familia',
    this.familyToggleSubtitle = 'Notificar o circulo de cuidado nos mesmos horarios',
  });

  final String title;
  final String subtitle;
  final List<AppointmentReminderOffset> offsets;
  final bool enabled;
  final ValueChanged<List<AppointmentReminderOffset>> onChanged;
  final bool notifyFamily;
  final ValueChanged<bool>? onNotifyFamilyChanged;
  final String familyToggleTitle;
  final String familyToggleSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        ..._buildRows(context),
        if (_canAddMore)
          TextButton.icon(
            onPressed: enabled ? () => _addAlert(context) : null,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar alerta'),
          ),
        if (onNotifyFamilyChanged != null) ...[
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(familyToggleTitle),
            subtitle: Text(familyToggleSubtitle),
            value: notifyFamily,
            onChanged: enabled ? onNotifyFamilyChanged : null,
          ),
        ],
      ],
    );
  }

  bool get _canAddMore =>
      offsets.length < AppointmentReminderOffset.maxPerList;

  List<Widget> _buildRows(BuildContext context) {
    if (offsets.isEmpty) {
      return [
        _ReminderRow(
          label: 'Alerta',
          value: null,
          enabled: enabled,
          canRemove: false,
          exclude: const {},
          onPick: (picked) {
            if (picked == null) return;
            onChanged([picked]);
          },
        ),
      ];
    }

    return [
      for (var i = 0; i < offsets.length; i++)
        _ReminderRow(
          label: offsets.length == 1 ? 'Alerta' : 'Alerta ${i + 1}',
          value: offsets[i],
          enabled: enabled,
          canRemove: true,
          exclude: {
            for (var j = 0; j < offsets.length; j++)
              if (j != i) offsets[j],
          },
          onPick: (picked) {
            final next = List<AppointmentReminderOffset>.from(offsets);
            if (picked == null) {
              next.removeAt(i);
            } else {
              next[i] = picked;
            }
            onChanged(AppointmentReminderOffset.sorted(next));
          },
          onRemove: () {
            final next = List<AppointmentReminderOffset>.from(offsets)
              ..removeAt(i);
            onChanged(next);
          },
        ),
    ];
  }

  Future<void> _addAlert(BuildContext context) async {
    final exclude = offsets.toSet();
    final picked = await showAppointmentReminderPicker(
      context,
      exclude: exclude,
    );
    if (picked == null) return;
    final next = List<AppointmentReminderOffset>.from(offsets)..add(picked);
    onChanged(AppointmentReminderOffset.sorted(next));
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.canRemove,
    required this.exclude,
    required this.onPick,
    this.onRemove,
  });

  final String label;
  final AppointmentReminderOffset? value;
  final bool enabled;
  final bool canRemove;
  final Set<AppointmentReminderOffset> exclude;
  final ValueChanged<AppointmentReminderOffset?> onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value?.label ?? 'Nenhum'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canRemove && onRemove != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              color: AppTheme.textSecondary,
              onPressed: enabled ? onRemove : null,
              tooltip: 'Remover',
            ),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: enabled ? () => _openPicker(context) : null,
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showAppointmentReminderPicker(
      context,
      exclude: exclude,
    );
    onPick(picked);
  }
}

/// Bottom sheet com opcoes de offset + Nenhum.
Future<AppointmentReminderOffset?> showAppointmentReminderPicker(
  BuildContext context, {
  Set<AppointmentReminderOffset> exclude = const {},
}) {
  final options = AppointmentReminderOffset.pickerOptions
      .where((o) => !exclude.contains(o))
      .toList();

  return showModalBottomSheet<AppointmentReminderOffset?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final maxHeight = MediaQuery.sizeOf(context).height * 0.55;

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Alerta',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text('Nenhum'),
                      onTap: () => Navigator.pop(context),
                    ),
                    for (final option in options)
                      ListTile(
                        title: Text(option.label),
                        onTap: () => Navigator.pop(context, option),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
