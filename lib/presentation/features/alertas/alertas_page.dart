import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/notification_preferences_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/notification/entities/notification_category.dart';
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

  static const List<_Alerta> _atencao = [
    _Alerta(
      titulo: 'Losartana das 20h ainda não confirmada',
      descricao:
          'O Sr. Joaquim ainda não tomou o medicamento das 20h. Alguém pode verificar?',
      hora: '20:42',
      icone: Icons.medication_outlined,
      categoria: 'Medicamentos',
      resolvido: false,
    ),
    _Alerta(
      titulo: 'Consulta de Cardiologia se aproxima',
      descricao: 'Quinta, 19 de junho às 10:30 com a Dra. Helena Vasconcelos.',
      hora: 'Hoje, 09:00',
      icone: Icons.calendar_today_outlined,
      categoria: 'Consultas',
      resolvido: false,
    ),
    _Alerta(
      titulo: 'Lembrete de hidratação',
      descricao:
          'Sr. Joaquim não registra ingestão de água há mais de 2 horas. Oferecer um copo agora ajuda a manter o ritmo do dia.',
      hora: '19:45',
      icone: Icons.water_drop_outlined,
      categoria: 'Hidratação',
      resolvido: false,
    ),
  ];

  static const List<_Alerta> _resolvidos = [
    _Alerta(
      titulo: 'Pressão arterial dentro do esperado',
      descricao: 'Karina registrou 128 x 82 mmHg às 14:30.',
      hora: '14:30',
      icone: Icons.check_circle_outline,
      categoria: 'Vitais',
      resolvido: true,
    ),
    _Alerta(
      titulo: 'Rafael entrou no Círculo Familiar',
      descricao: 'Convite aceito. Papel definido como observador.',
      hora: 'Ontem',
      icone: Icons.check_circle_outline,
      categoria: 'Família',
      resolvido: true,
    ),
    _Alerta(
      titulo: 'Metformina das 19h confirmada',
      descricao: 'Karina registrou a confirmação às 19:00.',
      hora: '19:00',
      icone: Icons.check_circle_outline,
      categoria: 'Medicamentos',
      resolvido: true,
    ),
  ];

  List<_Alerta> _filtrar(List<_Alerta> lista) {
    final preferences = ref.watch(notificationPreferencesProvider);

    final habilitados = lista.where((alerta) {
      final category = NotificationCategory.fromFilterLabel(alerta.categoria);
      if (category == null) return true;
      return preferences.isAlertEnabled(category);
    });

    if (_filtroSelecionado == 'Todas') return habilitados.toList();
    return habilitados
        .where((alerta) => alerta.categoria == _filtroSelecionado)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final atencaoFiltrado = _filtrar(_atencao);
    final resolvidosFiltrado = _filtrar(_resolvidos);
    final nenhumAlerta =
        atencaoFiltrado.isEmpty && resolvidosFiltrado.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
            'Nenhum alerta visível',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Ajuste as categorias em Perfil → Notificações → Alertas no app.',
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
    required List<_Alerta> alertas,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...alertas.map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCardAlerta(context, a),
          ),
        ),
      ],
    );
  }

  Widget _buildCardAlerta(BuildContext context, _Alerta alerta) {
    final corIcone = alerta.resolvido
        ? AppTheme.successForeground(context)
        : AppTheme.primary;
    final corFundo = alerta.resolvido
        ? AppTheme.successSurface(context)
        : AppTheme.cardSurface(context);
    final corBorda = alerta.resolvido
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
            child: Icon(alerta.icone, color: corIcone, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerta.titulo,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  alerta.descricao,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  alerta.hora,
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

class _Alerta {
  final String titulo;
  final String descricao;
  final String hora;
  final IconData icone;
  final String categoria;
  final bool resolvido;
  const _Alerta({
    required this.titulo,
    required this.descricao,
    required this.hora,
    required this.icone,
    required this.categoria,
    required this.resolvido,
  });
}
