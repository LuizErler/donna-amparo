import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/medication/entities/medication_summary.dart';
import '../../care/providers/care_providers.dart';
import '../../care/providers/care_team_providers.dart';
import '../../medication/add_medication_sheet.dart';
import '../../medication/providers/medication_providers.dart';
import '../../shared/refresh_providers.dart';
import '../../shared/widgets/pull_to_refresh_scroll_view.dart';

class MedicamentosGerenciarPage extends ConsumerWidget {
  const MedicamentosGerenciarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(patientMedicationsProvider);
    final roleAsync = ref.watch(currentCareRoleProvider);
    final canManage = roleAsync.maybeWhen(
      data: (role) => role?.canCreateMedsAndAppointments ?? false,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar medicamentos'),
      ),
      body: medsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (meds) => _buildList(context, ref, meds, canManage),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => _onAdd(context, ref),
              tooltip: 'Adicionar medicamento',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _onAdd(BuildContext context, WidgetRef ref) async {
    final patient = await ref.read(activePatientProvider.future);
    if (!context.mounted || patient == null) return;

    final saved = await showMedicationFormSheet(
      context,
      ref,
      patientId: patient.id,
    );
    if (!context.mounted || saved != true) return;
    _snack(context, 'Medicamento cadastrado com sucesso.');
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<MedicationSummary> meds,
    bool canManage,
  ) {
    Future<void> onRefresh(WidgetRef ref) =>
        refreshFutureProvider(ref, patientMedicationsProvider);

    if (meds.isEmpty) {
      return PullToRefreshListView(
        onRefresh: onRefresh,
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Nenhum medicamento cadastrado.\n'
            'Toque em + para adicionar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    final active = meds.where((m) => m.isActive).toList();
    final inactive = meds.where((m) => !m.isActive).toList();

    return PullToRefreshListView(
      onRefresh: onRefresh,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
      children: [
        if (active.isNotEmpty) ...[
          Text('Ativos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...active.map(
            (m) => _MedTile(med: m, canManage: canManage),
          ),
        ],
        if (inactive.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Encerrados',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...inactive.map(
            (m) => _MedTile(med: m, canManage: false),
          ),
        ],
      ],
    );
  }

  void _snack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _MedTile extends ConsumerWidget {
  const _MedTile({required this.med, required this.canManage});

  final MedicationSummary med;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: med.isActive
            ? AppTheme.cardNormal
            : AppTheme.cardNormal.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: med.isActive
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${med.frequencyLabel} · ${med.periodLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (canManage && med.isActive)
            PopupMenuButton<String>(
              onSelected: (value) => _onAction(context, ref, value),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'end', child: Text('Encerrar')),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    final patient = await ref.read(activePatientProvider.future);
    if (!context.mounted || patient == null) return;

    if (value == 'edit') {
      final saved = await showMedicationFormSheet(
        context,
        ref,
        patientId: patient.id,
        existing: med,
      );
      if (!context.mounted || saved != true) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicamento atualizado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (value == 'end') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Encerrar medicamento?'),
          content: Text(
            'Encerrar ${med.name}? Doses já confirmadas serão mantidas no histórico.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Encerrar'),
            ),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;

      final error = await deactivateMedication(
        ref,
        patientId: patient.id,
        medicationId: med.id,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Medicamento encerrado.'),
          backgroundColor: error != null ? Colors.red.shade700 : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
