import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/appointment/entities/appointment.dart';
import '../shared/app_snackbar.dart';
import 'add_appointment_sheet.dart';
import 'providers/appointment_providers.dart';

/// `true` se houve edicao ou cancelamento.
Future<bool?> showAppointmentDetailSheet(
  BuildContext context,
  WidgetRef ref, {
  required String patientId,
  required Appointment appointment,
  required bool canManage,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _AppointmentDetailSheet(
      patientId: patientId,
      appointment: appointment,
      canManage: canManage,
    ),
  );
}

class _AppointmentDetailSheet extends ConsumerStatefulWidget {
  const _AppointmentDetailSheet({
    required this.patientId,
    required this.appointment,
    required this.canManage,
  });

  final String patientId;
  final Appointment appointment;
  final bool canManage;

  @override
  ConsumerState<_AppointmentDetailSheet> createState() =>
      _AppointmentDetailSheetState();
}

class _AppointmentDetailSheetState extends ConsumerState<_AppointmentDetailSheet> {
  bool _loading = false;

  Appointment get _appointment => widget.appointment;

  Future<void> _onEdit() async {
    final saved = await showAppointmentFormSheet(
      context,
      ref,
      patientId: widget.patientId,
      existing: _appointment,
    );
    if (!mounted) return;
    if (saved == true) Navigator.of(context).pop(true);
  }

  Future<void> _onCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar consulta?'),
        content: const Text(
          'A consulta sera removida da agenda. Esta acao nao pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar consulta'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    final error = await deleteAppointment(
      ref,
      patientId: widget.patientId,
      appointmentId: _appointment.id,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      showAppSnack(context, error, variant: AppSnackVariant.error);
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isUpcoming = _appointment.isUpcoming();

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
                color: AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  _appointment.displaySpecialty,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (isUpcoming)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PROXIMA',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _appointment.visitTypeLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          _detailRow(
            context,
            icon: Icons.person_outline,
            label: 'Medico(a)',
            value: _appointment.displayDoctor.isEmpty
                ? 'Nao informado'
                : _appointment.displayDoctor,
          ),
          const SizedBox(height: 12),
          _detailRow(
            context,
            icon: Icons.access_time,
            label: 'Data e horario',
            value: _appointment.scheduleLabel.isEmpty
                ? 'Nao informado'
                : _appointment.scheduleLabel,
          ),
          const SizedBox(height: 12),
          _detailRow(
            context,
            icon: Icons.location_on_outlined,
            label: 'Local',
            value: _appointment.displayLocation.isEmpty
                ? 'Nao informado'
                : _appointment.displayLocation,
          ),
          if (_appointment.notes?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Text(
              'Anotacoes',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              _appointment.notes!.trim(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          _detailRow(
            context,
            icon: Icons.notifications_outlined,
            label: 'Lembrete 24h',
            value: _appointment.reminder24h ? 'Ativado' : 'Desativado',
          ),
          const SizedBox(height: 8),
          _detailRow(
            context,
            icon: Icons.group_outlined,
            label: 'Avisar familia',
            value: _appointment.notifyTeam ? 'Sim' : 'Nao',
          ),
          if (widget.canManage) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _onEdit,
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
                    : const Text('Editar'),
              ),
            ),
            if (isUpcoming) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _loading ? null : _onCancel,
                  child: const Text('Cancelar consulta'),
                ),
              ),
            ],
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

  Widget _detailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      )),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
