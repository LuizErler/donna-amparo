import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_message_mapper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/medication/entities/medication_day_period.dart';
import '../../../domain/medication/entities/medication_dose.dart';
import '../../../domain/medication/entities/medication_doses_result.dart';
import '../../care/providers/care_providers.dart';
import '../../care/providers/care_team_providers.dart';
import '../../medication/add_medication_sheet.dart';
import '../../medication/providers/medication_providers.dart';
import '../../shared/app_snackbar.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/error_state_view.dart';
import '../../shared/widgets/loading_state_view.dart';
import '../../shared/refresh_providers.dart';
import '../../shared/widgets/pull_to_refresh_scroll_view.dart';
import '../../shell/shell_page_header.dart';
import 'medicamentos_gerenciar_page.dart';

class MedicamentosPage extends ConsumerWidget {
  const MedicamentosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dosesAsync = ref.watch(medicationDosesProvider);
    final roleAsync = ref.watch(currentCareRoleProvider);
    final canToggle = roleAsync.maybeWhen(
      data: (role) => role?.canLogDosesAndVitals ?? false,
      orElse: () => false,
    );
    final canManage = roleAsync.maybeWhen(
      data: (role) => role?.canCreateMedsAndAppointments ?? false,
      orElse: () => false,
    );

    return Scaffold(
      body: SafeArea(
        child: dosesAsync.when(
          loading: () => const LoadingStateView(),
          error: (error, _) => _buildError(context, error),
          data: (result) => _buildContent(
            context,
            ref,
            result,
            canToggle,
            canManage,
          ),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => _onAddMedication(context, ref),
              tooltip: 'Adicionar medicamento',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _onAddMedication(BuildContext context, WidgetRef ref) async {
    final patient = await ref.read(activePatientProvider.future);
    if (!context.mounted) return;
    if (patient == null) {
      showAppSnack(
        context,
        'Paciente não encontrado.',
        variant: AppSnackVariant.error,
      );
      return;
    }

    final saved = await showMedicationFormSheet(
      context,
      ref,
      patientId: patient.id,
    );
    if (!context.mounted || saved != true) return;
    showAppSuccessSnack(context, 'Medicamento cadastrado com sucesso.');
  }

  void _openGerenciar(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MedicamentosGerenciarPage(),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShellPageHeader(
            title: 'Medicamentos',
            subtitle: 'Doses do dia e confirmações.',
          ),
          ErrorStateView(
            message: mapErrorMessage(
              error,
              fallback: 'Não foi possível carregar os medicamentos.',
            ),
            centered: false,
            alignStart: true,
            padding: const EdgeInsets.only(top: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    MedicationDosesResult result,
    bool canToggle,
    bool canManage,
  ) {
    final today = result.today;
    final morning = today
        .where((d) => d.period == MedicationDayPeriod.morning)
        .toList();
    final afternoon = today
        .where((d) => d.period == MedicationDayPeriod.afternoon)
        .toList();
    final evening = today
        .where((d) => d.period == MedicationDayPeriod.evening)
        .toList();

    return PullToRefreshScrollView(
      onRefresh: (ref) => refreshFutureProvider(ref, medicationDosesProvider),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShellPageHeader(
            title: 'Medicamentos',
            subtitle: 'Doses do dia e confirmações.',
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _openGerenciar(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Gerenciar medicamentos'),
            ),
          ),
          const SizedBox(height: 16),
          if (result.overdue.isNotEmpty)
            _buildOverdueSection(
              context,
              ref,
              result.overdue,
              canToggle,
            ),
          if (result.overdue.isNotEmpty) const SizedBox(height: 20),
          if (today.isEmpty && result.overdue.isEmpty)
            _buildEmptyState(context)
          else if (today.isNotEmpty) ...[
            _buildProgresso(context, result.takenToday, result.totalToday),
            const SizedBox(height: 28),
            if (morning.isNotEmpty)
              _buildPeriodo(
                context,
                ref,
                MedicationDayPeriod.morning,
                Icons.wb_sunny_outlined,
                morning,
                canToggle,
              ),
            if (morning.isNotEmpty &&
                (afternoon.isNotEmpty || evening.isNotEmpty))
              const SizedBox(height: 20),
            if (afternoon.isNotEmpty)
              _buildPeriodo(
                context,
                ref,
                MedicationDayPeriod.afternoon,
                Icons.wb_cloudy_outlined,
                afternoon,
                canToggle,
              ),
            if (afternoon.isNotEmpty && evening.isNotEmpty)
              const SizedBox(height: 20),
            if (evening.isNotEmpty)
              _buildPeriodo(
                context,
                ref,
                MedicationDayPeriod.evening,
                Icons.nightlight_outlined,
                evening,
                canToggle,
              ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOverdueSection(
    BuildContext context,
    WidgetRef ref,
    List<MedicationDose> overdue,
    bool canToggle,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppTheme.warningForeground(context), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${overdue.length} dose${overdue.length > 1 ? 's' : ''} atrasada${overdue.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.warningForegroundStrong(context),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (canToggle)
                TextButton(
                  onPressed: () => _resolveOverdue(context, ref, overdue),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.warningForegroundStrong(context),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Resolver'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...overdue.map(
            (dose) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildCardMedicamento(context, ref, dose, canToggle),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveOverdue(
    BuildContext context,
    WidgetRef ref,
    List<MedicationDose> overdue,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolver doses atrasadas?'),
        content: Text(
          'Registrar ${overdue.length} dose${overdue.length > 1 ? 's' : ''} '
          'como não tomada${overdue.length > 1 ? 's' : ''}? '
          'Ficarão no histórico para relatórios.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final error = await resolveAllOverdueDoses(ref, overdue: overdue);
    if (!context.mounted) return;
    if (error != null) {
      showAppSnack(context, error, variant: AppSnackVariant.error);
    } else {
      showAppSuccessSnack(context, 'Doses registradas como não tomadas.');
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return const EmptyStateView(
      icon: Icons.medication_outlined,
      title: 'Nenhum medicamento hoje',
      message:
          'Nenhum medicamento cadastrado para hoje.\n'
          'Toque em + para cadastrar o primeiro remedio.',
    );
  }

  Widget _buildProgresso(BuildContext context, int totalTaken, int total) {
    final pct = total == 0 ? 0.0 : totalTaken / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progresso de hoje',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.white70, fontWeight: FontWeight.w600)),
              Text('$totalTaken de $total doses',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pct == 1.0
                ? 'Todas as doses confirmadas!'
                : '${total - totalTaken} doses pendentes para hoje.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodo(
    BuildContext context,
    WidgetRef ref,
    MedicationDayPeriod period,
    IconData icone,
    List<MedicationDose> lista,
    bool canToggle,
  ) {
    final todosTomados = lista.every((d) => d.taken);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, size: 18, color: AppTheme.onSurfaceSecondary(context)),
            const SizedBox(width: 6),
            Text(period.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            if (todosTomados)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.successSurface(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Completo',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.successForeground(context),
                          fontWeight: FontWeight.w600,
                        )),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ...lista.map(
          (dose) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCardMedicamento(context, ref, dose, canToggle),
          ),
        ),
      ],
    );
  }

  Widget _buildCardMedicamento(
    BuildContext context,
    WidgetRef ref,
    MedicationDose dose,
    bool canToggle,
  ) {
    final isOverdue = dose.isOverdue;
    return AppCard(
      color: dose.taken
          ? AppTheme.successSurface(context)
          : isOverdue
              ? AppTheme.warningSurface(context)
              : null,
      borderColor: dose.taken
          ? AppTheme.successBorder(context)
          : isOverdue
              ? AppTheme.warningBorder(context)
              : null,
      child: Row(
        children: [
          GestureDetector(
            onTap: canToggle && !isOverdue
                ? () => _onToggleDose(context, ref, dose)
                : null,
            onLongPress: canToggle && isOverdue
                ? () => _onMarkNotTaken(context, ref, dose)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: dose.taken ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: dose.taken
                      ? Colors.green
                      : AppTheme.cardOutline(context),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: dose.taken
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration:
                            dose.taken ? TextDecoration.lineThrough : null,
                        color: dose.taken
                            ? AppTheme.onSurfaceSecondary(context)
                            : AppTheme.onSurface(context),
                      ),
                ),
                if (isOverdue) ...[
                  const SizedBox(height: 2),
                  Text(
                    dose.overdueLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.warningForeground(context),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                if (dose.instructions.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dose.instructions,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: dose.taken
                              ? AppTheme.onSurfaceSecondary(context)
                                  .withValues(alpha: 0.7)
                              : AppTheme.onSurfaceSecondary(context),
                        ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: dose.taken
                      ? AppTheme.successSurface(context)
                      : isOverdue
                          ? AppTheme.warningSurface(context)
                          : AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dose.timeLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: dose.taken
                            ? AppTheme.successForeground(context)
                            : isOverdue
                                ? AppTheme.warningForeground(context)
                                : AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dose.taken
                    ? 'Confirmado'
                    : isOverdue
                        ? 'Atrasada'
                        : 'Pendente',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: dose.taken
                          ? AppTheme.successForegroundMuted(context)
                          : AppTheme.onSurfaceSecondary(context),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onToggleDose(
    BuildContext context,
    WidgetRef ref,
    MedicationDose dose,
  ) async {
    final error = await toggleMedicationDoseTaken(
      ref,
      medicationId: dose.medicationId,
      scheduleId: dose.scheduleId > 0 ? dose.scheduleId : null,
      scheduledTime: dose.scheduledTime,
      scheduledFor: dose.scheduledFor,
      taken: !dose.taken,
    );
    if (!context.mounted) return;
    if (error != null) {
      showAppSnack(context, error, variant: AppSnackVariant.error);
    }
  }

  Future<void> _onMarkNotTaken(
    BuildContext context,
    WidgetRef ref,
    MedicationDose dose,
  ) async {
    final error = await markDoseNotTaken(ref, dose: dose);
    if (!context.mounted) return;
    if (error != null) {
      showAppSnack(context, error, variant: AppSnackVariant.error);
    } else {
      showAppSuccessSnack(context, 'Registrada como não tomada.');
    }
  }
}
