import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/notification_preferences_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/alert/entities/family_alert.dart';
import '../../../domain/alert/entities/family_alerts_result.dart';
import '../../alertas/providers/alerts_providers.dart';
import '../../appointment/providers/appointment_providers.dart';
import '../../hydration/providers/hydration_providers.dart';
import '../../medication/providers/medication_providers.dart';
import '../../shared/refresh_providers.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/pull_to_refresh_scroll_view.dart';
import '../../shell/shell_page_header.dart';

class AlertasPage extends ConsumerStatefulWidget {
  const AlertasPage({super.key});

  @override
  ConsumerState<AlertasPage> createState() => _AlertasPageState();
}

class _AlertasPageState extends ConsumerState<AlertasPage> {
  String _filtroSelecionado = 'Todas';

  static const List<String> _filtros = [
    'Todas',
    'Medicamentos',
    'Consultas',
    'Vitais',
    'Hidratação',
    'Família',
  ];

  List<FamilyAlert> _filtrar(List<FamilyAlert> lista) {
    final preferences = ref.watch(notificationPreferencesProvider);

    final habilitados = lista.where((alerta) {
      return preferences.isAlertEnabled(alerta.category);
    });

    if (_filtroSelecionado == 'Todas') return habilitados.toList();
    return habilitados
        .where((alerta) => alerta.filterLabel == _filtroSelecionado)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(familyAlertsProvider);

    return Scaffold(
      body: SafeArea(
        child: AsyncStateView<FamilyAlertsResult>(
          value: alertsAsync,
          errorFallback: 'Não foi possível carregar os alertas.',
          data: (result) {
            final atencaoFiltrado = _filtrar(result.attention);
            final resolvidosFiltrado = _filtrar(result.resolved);
            final nenhumAlerta =
                atencaoFiltrado.isEmpty && resolvidosFiltrado.isEmpty;

            return PullToRefreshScrollView(
              onRefresh: _refreshAlerts,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildFiltros(context),
                  const SizedBox(height: 28),
                  if (nenhumAlerta)
                    _buildEmptyState(context)
                  else ...[
                    if (atencaoFiltrado.isNotEmpty) ...[
                      _buildSecaoAlertas(
                        context,
                        titulo: 'Atenção (${atencaoFiltrado.length})',
                        alertas: atencaoFiltrado,
                      ),
                      const SizedBox(height: 28),
                    ],
                    if (resolvidosFiltrado.isNotEmpty)
                      _buildSecaoAlertas(
                        context,
                        titulo: 'Resolvidos (${resolvidosFiltrado.length})',
                        alertas: resolvidosFiltrado,
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const ShellPageHeader(
      title: 'Alertas da Família',
      subtitle: 'Pendências e itens resolvidos.',
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardOutline(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color: AppTheme.onSurfaceSecondary(context),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum alerta no momento',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Quando houver pendências de medicamentos, hidratação ou consultas, elas aparecerão aqui. Ajuste as categorias em Perfil → Notificações.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filtros.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selecionado = _filtros[i] == _filtroSelecionado;
          return GestureDetector(
            onTap: () => setState(() => _filtroSelecionado = _filtros[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selecionado
                    ? AppTheme.primary
                    : AppTheme.cardSurface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selecionado
                      ? AppTheme.primary
                      : AppTheme.cardOutline(context),
                ),
              ),
              child: Text(
                _filtros[i],
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selecionado
                          ? Colors.white
                          : AppTheme.onSurfaceSecondary(context),
                      fontWeight:
                          selecionado ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecaoAlertas(
    BuildContext context, {
    required String titulo,
    required List<FamilyAlert> alertas,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...alertas.map(
          (alerta) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCardAlerta(context, alerta),
          ),
        ),
      ],
    );
  }

  Widget _buildCardAlerta(BuildContext context, FamilyAlert alerta) {
    final corIcone = alerta.resolved
        ? AppTheme.successForeground(context)
        : AppTheme.primary;
    final corFundo = alerta.resolved
        ? AppTheme.successSurface(context)
        : AppTheme.cardSurface(context);
    final corBorda = alerta.resolved
        ? AppTheme.successBorder(context)
        : AppTheme.cardOutline(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corBorda),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: corIcone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(alerta.icon, color: corIcone, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerta.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  alerta.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  alerta.timeLabel,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _refreshAlerts(WidgetRef ref) async {
  await refreshFutureProviders(ref, [
    medicationDosesProvider,
    hydrationStatusProvider,
    patientAppointmentsProvider,
  ]);
  ref.invalidate(familyAlertsProvider);
}
