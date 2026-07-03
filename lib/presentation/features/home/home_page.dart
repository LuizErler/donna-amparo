import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/appointment/entities/appointment.dart';
import '../../../domain/appointment/entities/appointments_list_result.dart';
import '../../../domain/hydration/entities/hydration_status.dart';
import '../../../domain/medication/entities/medication_dose.dart';
import '../../../domain/medication/entities/medication_doses_result.dart';
import '../../appointment/appointment_detail_sheet.dart';
import '../../appointment/providers/appointment_providers.dart';
import '../../care/providers/care_providers.dart';
import '../../care/providers/care_team_providers.dart';
import '../../hydration/providers/hydration_providers.dart';
import '../../medication/providers/medication_providers.dart';
import '../../shared/app_snackbar.dart';
import '../../shared/refresh_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/loading_state_view.dart';
import '../../shared/widgets/pull_to_refresh_scroll_view.dart';
import '../../shell/shell_page_header.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careAsync = ref.watch(careContextProvider);
    final dosesAsync = ref.watch(medicationDosesProvider);
    final appointmentsAsync = ref.watch(patientAppointmentsProvider);
    final hydrationAsync = ref.watch(hydrationStatusProvider);
    final roleAsync = ref.watch(currentCareRoleProvider);
    final canToggle = roleAsync.maybeWhen(
      data: (role) => role?.canLogDosesAndVitals ?? false,
      orElse: () => false,
    );
    final canManageAppointments = roleAsync.maybeWhen(
      data: (role) => role?.canCreateMedsAndAppointments ?? false,
      orElse: () => false,
    );

    return Scaffold(
      body: SafeArea(
        child: PullToRefreshScrollView(
          onRefresh: _refreshHome,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, careAsync),
              const SizedBox(height: 24),
              _buildCardProximoMedicamento(context, ref, dosesAsync, canToggle),
              const SizedBox(height: 24),
              _buildHidratacao(
                context,
                ref,
                careAsync,
                hydrationAsync,
                canToggle,
              ),
              const SizedBox(height: 24),
              _buildProximaConsulta(
                context,
                ref,
                appointmentsAsync,
                canManageAppointments,
              ),
              const SizedBox(height: 24),
              _buildPendenciasFamilia(
                context,
                dosesAsync,
                hydrationAsync,
                careAsync,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<CareContext> careAsync) {
    return careAsync.when(
      loading: () => const ShellPageHeader(
        title: 'Carregando...',
        subtitle: 'Preparando seu painel.',
      ),
      error: (_, _) => const ShellPageHeader(
        title: 'Bem-vindo',
        subtitle: 'Veja o resumo do dia.',
      ),
      data: (ctx) => ShellPageHeader(
        title: 'Bom dia, ${ctx.caregiverFirstName}',
        subtitle: 'Veja como está o dia de ${ctx.patientName}.',
      ),
    );
  }

  Widget _buildCardProximoMedicamento(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<MedicationDosesResult> dosesAsync,
    bool canToggle,
  ) {
    return dosesAsync.when(
      loading: () => _buildMedicationCardShell(
        context,
        body: const LoadingStateView(compact: true, indicatorColor: Colors.white),
      ),
      error: (_, _) => _buildMedicationCardShell(
        context,
        subtitle: 'Não foi possível carregar as doses.',
      ),
      data: (result) {
        final next = result.nextPendingDose;
        if (next == null) {
          return _buildMedicationCardShell(
            context,
            subtitle: 'Nenhuma dose pendente no momento.',
          );
        }
        return _buildMedicationCardShell(
          context,
          title: next.isOverdue ? 'Dose atrasada' : 'Próximo medicamento',
          subtitle: _doseTimeLine(next),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                next.displayName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (next.instructions.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  next.instructions.trim(),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (canToggle) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _confirmDose(context, ref, next),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Confirmar dose'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _doseTimeLine(MedicationDose dose) {
    if (dose.isOverdue && dose.overdueLabel.isNotEmpty) {
      return '${dose.overdueLabel} · ${dose.timeLabel}';
    }
    return 'as ${dose.timeLabel}';
  }

  Future<void> _confirmDose(
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
      taken: true,
    );
    if (!context.mounted) return;
    if (error != null) {
      showAppSnack(context, error, variant: AppSnackVariant.error);
      return;
    }
    showAppSuccessSnack(context, 'Dose confirmada.');
  }

  Widget _buildMedicationCardShell(
    BuildContext context, {
    String title = 'Próximo medicamento',
    String? subtitle,
    Widget? body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
          ],
          if (body != null) ...[
            const SizedBox(height: 8),
            body,
          ],
        ],
      ),
    );
  }

  Widget _buildHidratacao(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<CareContext> careAsync,
    AsyncValue<HydrationStatus> hydrationAsync,
    bool canLog,
  ) {
    final patientName = careAsync.maybeWhen(
      data: (ctx) => ctx.patientName,
      orElse: () => 'paciente',
    );

    return hydrationAsync.when(
      loading: () => AppCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 14),
            Text(
              'Carregando hidratação...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      error: (_, _) => AppCard(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Não foi possível carregar a hidratação.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      data: (status) {
        final subtitle = status.lastLog == null
            ? 'Sem registros ainda'
            : 'Último registro ${status.elapsedLabel.toLowerCase()}';
        final messageColor = status.needsAttention
            ? Colors.orange.shade800
            : Theme.of(context).textTheme.bodyMedium?.color;

        return AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      status.needsAttention
                          ? Icons.water_drop
                          : Icons.water_drop_outlined,
                      color: status.needsAttention ? Colors.orange : Colors.blue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hidratação',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(subtitle,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                status.messageForPatient(patientName),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: messageColor,
                    ),
              ),
              if (canLog) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _registerHydration(context, ref),
                    child: const Text('Registrar água'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _registerHydration(BuildContext context, WidgetRef ref) async {
    final error = await recordHydration(ref);
    if (!context.mounted) return;
    if (error != null) {
      showAppSnack(context, error, variant: AppSnackVariant.error);
      return;
    }
    showAppSuccessSnack(context, 'Hidratação registrada.');
  }

  Widget _buildProximaConsulta(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<AppointmentsListResult> appointmentsAsync,
    bool canManage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Próxima consulta',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        appointmentsAsync.when(
          loading: () => AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 14),
                Text(
                  'Carregando consultas...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          error: (_, _) => AppCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Não foi possível carregar a próxima consulta.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          data: (result) {
            final next =
                result.upcoming.isNotEmpty ? result.upcoming.first : null;
            if (next == null) {
              return AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_hospital_outlined,
                          color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Nenhuma consulta agendada.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }

            final subtitle = _appointmentSubtitle(next);

            return AppCard(
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: () => _openAppointment(context, ref, next, canManage),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_hospital_outlined,
                            color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _appointmentTitle(next),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: Theme.of(context).textTheme.bodyMedium?.color),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _appointmentTitle(Appointment appointment) {
    final specialty = appointment.displaySpecialty;
    final doctor = appointment.displayDoctor;
    if (doctor.isEmpty) return specialty;
    return '$specialty — $doctor';
  }

  String _appointmentSubtitle(Appointment appointment) {
    final location = appointment.displayLocation;
    if (location.isEmpty) return appointment.scheduleLabel;
    return '${appointment.scheduleLabel} · $location';
  }

  Future<void> _openAppointment(
    BuildContext context,
    WidgetRef ref,
    Appointment appointment,
    bool canManage,
  ) async {
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

    final changed = await showAppointmentDetailSheet(
      context,
      ref,
      patientId: patient.id,
      appointment: appointment,
      canManage: canManage,
    );
    if (!context.mounted || changed != true) return;
    showAppSuccessSnack(context, 'Consulta atualizada.');
  }

  Widget _buildPendenciasFamilia(
    BuildContext context,
    AsyncValue<MedicationDosesResult> dosesAsync,
    AsyncValue<HydrationStatus> hydrationAsync,
    AsyncValue<CareContext> careAsync,
  ) {
    final patientName = careAsync.maybeWhen(
      data: (ctx) => ctx.patientName,
      orElse: () => 'paciente',
    );

    if (dosesAsync.isLoading || hydrationAsync.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pendências da família',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 14),
                Text(
                  'Carregando pendências...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final pendencias = <Widget>[];

    final doses = dosesAsync.valueOrNull;
    if (doses != null) {
      final pending = [
        ...doses.overdue,
        ...doses.today.where((d) => !d.taken && !d.isMarkedNotTaken),
      ];
      for (final dose in pending) {
        pendencias.add(
          _buildPendencia(
            context,
            icone: Icons.medication_outlined,
            titulo: dose.isOverdue
                ? 'Dose atrasada'
                : 'Medicamento das ${dose.timeLabel}',
            descricao: _pendenciaMedicamentoDescricao(dose),
            cor: Colors.orange,
          ),
        );
      }
    }

    final hydration = hydrationAsync.valueOrNull;
    if (hydration?.needsAttention == true) {
      pendencias.add(
        _buildPendencia(
          context,
          icone: Icons.water_drop_outlined,
          titulo: 'Hidratação',
          descricao: hydration!.messageForPatient(patientName),
          cor: Colors.blue,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pendências da família',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (pendencias.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Nenhuma pendência no momento.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          for (var i = 0; i < pendencias.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            pendencias[i],
          ],
      ],
    );
  }

  String _pendenciaMedicamentoDescricao(MedicationDose dose) {
    if (dose.isOverdue && dose.overdueLabel.isNotEmpty) {
      return '${dose.displayName} · ${dose.overdueLabel}. Alguém pode verificar?';
    }
    return 'O paciente ainda não tomou ${dose.displayName} (${dose.timeLabel}). Alguém pode verificar?';
  }

  Widget _buildPendencia(
    BuildContext context, {
    required IconData icone,
    required String titulo,
    required String descricao,
    required Color cor,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: cor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(descricao, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _refreshHome(WidgetRef ref) async {
  ref.invalidate(currentProfileProvider);
  ref.invalidate(activePatientProvider);
  ref.invalidate(hasActivePatientProvider);
  await refreshFutureProviders(ref, [
    medicationDosesProvider,
    patientAppointmentsProvider,
    hydrationStatusProvider,
  ]);
}
