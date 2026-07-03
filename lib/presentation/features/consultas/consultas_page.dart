import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/appointment/entities/appointment.dart';
import '../../../domain/appointment/entities/appointments_list_result.dart';
import '../../appointment/add_appointment_sheet.dart';
import '../../appointment/appointment_detail_sheet.dart';
import '../../appointment/providers/appointment_providers.dart';
import '../../appointment/widgets/appointment_highlight_card.dart';
import '../../appointment/widgets/appointment_history_card.dart';
import '../../appointment/widgets/appointment_upcoming_card.dart';
import '../../care/providers/care_providers.dart';
import '../../care/providers/care_team_providers.dart';
import '../../shared/app_snackbar.dart';
import '../../shared/refresh_providers.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/pull_to_refresh_scroll_view.dart';
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
    Future<void> onRefresh(WidgetRef ref) =>
        refreshFutureProvider(ref, patientAppointmentsProvider);

    if (result.isEmpty) {
      return PullToRefreshListView(
        onRefresh: onRefresh,
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

    return PullToRefreshScrollView(
      onRefresh: onRefresh,
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
                  AppointmentHighlightCard(
                    appointment: highlight,
                    onTap: () =>
                        _openAppointment(context, ref, highlight, canManage),
                  ),
                  if (otherUpcoming.isNotEmpty) const SizedBox(height: 12),
                ],
                for (var i = 0; i < otherUpcoming.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  AppointmentUpcomingCard(
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
                  AppointmentHistoryCard(
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
