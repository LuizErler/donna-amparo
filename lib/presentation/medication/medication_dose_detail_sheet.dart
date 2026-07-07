import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/medication/entities/medication_dose.dart';
import '../../domain/medication/entities/medication_summary.dart';
import '../shared/app_snackbar.dart';
import 'add_medication_sheet.dart';
import 'providers/medication_providers.dart';

/// `true` se houve confirmacao, edicao ou outra alteracao.
Future<bool?> showMedicationDoseDetailSheet(
  BuildContext context,
  WidgetRef ref, {
  required String patientId,
  required MedicationDose dose,
  required bool canToggle,
  required bool canManage,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _MedicationDoseDetailSheet(
      patientId: patientId,
      dose: dose,
      canToggle: canToggle,
      canManage: canManage,
    ),
  );
}

class _MedicationDoseDetailSheet extends ConsumerStatefulWidget {
  const _MedicationDoseDetailSheet({
    required this.patientId,
    required this.dose,
    required this.canToggle,
    required this.canManage,
  });

  final String patientId;
  final MedicationDose dose;
  final bool canToggle;
  final bool canManage;

  @override
  ConsumerState<_MedicationDoseDetailSheet> createState() =>
      _MedicationDoseDetailSheetState();
}

class _MedicationDoseDetailSheetState
    extends ConsumerState<_MedicationDoseDetailSheet> {
  bool _loading = false;

  MedicationDose get _dose => widget.dose;

  String get _statusLabel {
    if (_dose.taken) return 'Confirmada';
    if (_dose.isMarkedNotTaken) return 'Não tomada';
    if (_dose.isDueNow) {
      return _dose.overdueLabel.isNotEmpty ? _dose.overdueLabel : 'Atrasada';
    }
    return 'Pendente';
  }

  Color _statusColor(BuildContext context) {
    if (_dose.taken) return AppTheme.successForeground(context);
    if (_dose.isMarkedNotTaken) {
      return AppTheme.onSurfaceSecondary(context);
    }
    if (_dose.isDueNow) return AppTheme.warningForeground(context);
    return AppTheme.primary;
  }

  Color _statusSurface(BuildContext context) {
    if (_dose.taken) return AppTheme.successSurface(context);
    if (_dose.isDueNow) return AppTheme.warningSurface(context);
    return AppTheme.primary.withValues(alpha: 0.12);
  }

  Future<void> _runAction(Future<String?> Function() action) async {
    setState(() => _loading = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      showAppSnack(context, error, variant: AppSnackVariant.error);
      return;
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _onConfirmOrUnconfirm() async {
    await _runAction(
      () => toggleMedicationDoseTaken(
        ref,
        medicationId: _dose.medicationId,
        scheduleId: _dose.scheduleId > 0 ? _dose.scheduleId : null,
        scheduledTime: _dose.scheduledTime,
        scheduledFor: _dose.scheduledFor,
        taken: !_dose.taken,
      ),
    );
  }

  Future<void> _onMarkNotTaken() async {
    await _runAction(() => markDoseNotTaken(ref, dose: _dose));
  }

  Future<void> _onEditMedication() async {
    final meds = await ref.read(patientMedicationsProvider.future);
    if (!mounted) return;

    MedicationSummary? summary;
    for (final med in meds) {
      if (med.id == _dose.medicationId) {
        summary = med;
        break;
      }
    }

    if (summary == null) {
      showAppSnack(
        context,
        'Medicamento não encontrado.',
        variant: AppSnackVariant.error,
      );
      return;
    }

    final saved = await showMedicationFormSheet(
      context,
      ref,
      patientId: widget.patientId,
      existing: summary,
    );
    if (!mounted) return;
    if (saved == true) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final canActOnDose = widget.canToggle &&
        !_dose.isPastDayOverdue &&
        !_dose.isMarkedNotTaken;
    final canMarkNotTaken = widget.canToggle &&
        _dose.isPastDayOverdue &&
        !_dose.taken &&
        !_dose.isMarkedNotTaken;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardOutline(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  _dose.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusSurface(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _statusColor(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _dose.period.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceSecondary(context),
                ),
          ),
          const SizedBox(height: 20),
          _detailRow(
            context,
            icon: Icons.access_time,
            label: 'Data e horário',
            value: _scheduleLabel(_dose),
          ),
          const SizedBox(height: 12),
          _detailRow(
            context,
            icon: Icons.medication_outlined,
            label: 'Status',
            value: _statusLabel,
          ),
          if (_dose.instructions.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Instruções',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              _dose.instructions.trim(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (widget.canToggle && canActOnDose) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _onConfirmOrUnconfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_dose.taken ? 'Desmarcar confirmação' : 'Confirmar dose'),
              ),
            ),
          ],
          if (canMarkNotTaken) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _loading ? null : _onMarkNotTaken,
                child: const Text('Marcar como não tomada'),
              ),
            ),
          ],
          if (widget.canManage) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _loading ? null : _onEditMedication,
                child: const Text('Editar medicamento'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: _loading ? null : () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ),
        ],
      ),
    );
  }

  static String _scheduleLabel(MedicationDose dose) {
    const weekdays = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    final day = dose.scheduledFor;
    final weekday = weekdays[day.weekday - 1];
    final month = months[day.month - 1];
    return '$weekday, ${day.day} de $month · ${dose.timeLabel}';
  }

  Widget _detailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.onSurfaceSecondary(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.onSurfaceSecondary(context),
                    ),
              ),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
