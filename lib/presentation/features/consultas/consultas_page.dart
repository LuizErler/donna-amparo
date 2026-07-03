import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/appointment/entities/appointment.dart';
import '../../../domain/appointment/entities/appointments_list_result.dart';
import '../../appointment/add_appointment_sheet.dart';
import '../../appointment/appointment_detail_sheet.dart';
import '../../appointment/providers/appointment_providers.dart';
import '../../care/providers/care_providers.dart';
import '../../care/providers/care_team_providers.dart';
import '../../shared/app_snackbar.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shell/shell_page_header.dart';

class ConsultasPage extends ConsumerWidget {
  const ConsultasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(patientAppointmentsProvider);
    final roleAsync = ref.watch(currentCareRoleProvider);
    final canManage = roleAsync.maybeWhen(
      data: (role) => role?.canCreateMedsAndAppointments ?? false,
      orElse: () => false,
    );

    return Scaffold(
      body: SafeArea(
        child: AsyncStateView<AppointmentsListResult>(
          value: appointmentsAsync,
          errorFallback: 'Nao foi possivel carregar as consultas.',
          data: (result) => _buildContent(context, ref, result, canManage),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => _onAddAppointment(context, ref),
              tooltip: 'Agendar consulta',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _onAddAppointment(BuildContext context, WidgetRef ref) async {
    final patient = await ref.read(activePatientProvider.future);
    if (!context.mounted) return;
    if (patient == null) {
      showAppSnack(
        context,
        'Paciente nao encontrado.',
        variant: AppSnackVariant.error,
      );
      return;
    }

    final saved = await showAddAppointmentSheet(
      context,
      ref,
      patientId: patient.id,
    );
    if (!context.mounted || saved != true) return;
    showAppSuccessSnack(context, 'Consulta agendada com sucesso.');
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
        'Paciente nao encontrado.',
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

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppointmentsListResult result,
    bool canManage,
  ) {
    if (result.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: const [
          ShellPageHeader(
            title: 'Consultas',
            subtitle: 'Agenda medica e historico.',
          ),
          SizedBox(height: 48),
          EmptyStateView(
            icon: Icons.medical_services_outlined,
            title: 'Nenhuma consulta',
            message:
                'Agende consultas e exames para acompanhar a agenda medica.',
          ),
        ],
      );
    }

    final highlight = result.upcoming.isNotEmpty ? result.upcoming.first : null;
    final otherUpcoming =
        highlight != null ? result.upcoming.skip(1).toList() : result.upcoming;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(patientAppointmentsProvider);
        await ref.read(patientAppointmentsProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            if (result.upcoming.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildSection(
                context,
                titulo: 'Proximas',
                children: [
                  if (highlight != null) ...[
                    _AppointmentHighlightCard(
                      appointment: highlight,
                      onTap: () =>
                          _openAppointment(context, ref, highlight, canManage),
                    ),
                    if (otherUpcoming.isNotEmpty) const SizedBox(height: 12),
                  ],
                  for (var i = 0; i < otherUpcoming.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _AppointmentUpcomingCard(
                      appointment: otherUpcoming[i],
                      onTap: () => _openAppointment(
                        context,
                        ref,
                        otherUpcoming[i],
                        canManage,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (result.past.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildSection(
                context,
                titulo: 'Historico',
                children: [
                  for (var i = 0; i < result.past.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _AppointmentHistoryCard(
                      appointment: result.past[i],
                      onTap: () => _openAppointment(
                        context,
                        ref,
                        result.past[i],
                        canManage,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const ShellPageHeader(
      title: 'Consultas',
      subtitle: 'Agenda medica e historico.',
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String titulo,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _AppointmentHighlightCard extends StatelessWidget {
  const _AppointmentHighlightCard({
    required this.appointment,
    required this.onTap,
  });

  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appointment.displaySpecialty,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PROXIMA',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                    ),
                  ),
                ],
              ),
              if (appointment.displayDoctor.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  appointment.displayDoctor,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appointment.scheduleLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              if (appointment.displayLocation.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appointment.displayLocation,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
              if (appointment.notes?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    appointment.notes!.trim(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentUpcomingCard extends StatelessWidget {
  const _AppointmentUpcomingCard({
    required this.appointment,
    required this.onTap,
  });

  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.cardNormal,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_outlined,
                      color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.displaySpecialty,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (appointment.displayDoctor.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          appointment.displayDoctor,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        appointment.scheduleLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      if (appointment.displayLocation.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          appointment.displayLocation,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentHistoryCard extends StatelessWidget {
  const _AppointmentHistoryCard({
    required this.appointment,
    required this.onTap,
  });

  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final location = appointment.displayLocation;
    final subtitle = location.isEmpty
        ? appointment.historyLabel
        : '${appointment.historyLabel} · $location';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.cardNormal,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.displaySpecialty,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (appointment.displayDoctor.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        appointment.displayDoctor,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              if (appointment.notes?.trim().isNotEmpty == true)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_note,
                              size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'ANOTACOES',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        appointment.notes!.trim(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
