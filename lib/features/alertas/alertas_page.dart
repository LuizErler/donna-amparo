import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AlertasPage extends StatefulWidget {
  const AlertasPage({super.key});

  @override
  State<AlertasPage> createState() => _AlertasPageState();
}

class _AlertasPageState extends State<AlertasPage> {
  String _filtroSelecionado = 'Todas';

  static const List<String> _filtros = [
    'Todas', 'Medicamentos', 'Consultas', 'Vitais', 'Hidratacao', 'Familia'
  ];

  static const List<_Alerta> _atencao = [
    _Alerta(
      titulo: 'Losartana das 20h ainda nao confirmada',
      descricao: 'O Sr. Joaquim ainda nao tomou o medicamento das 20h. Alguem pode verificar?',
      hora: '20:42',
      icone: Icons.medication_outlined,
      categoria: 'Medicamentos',
      resolvido: false,
    ),
    _Alerta(
      titulo: 'Consulta de Cardiologia se aproxima',
      descricao: 'Quinta, 19 de junho as 10:30 com a Dra. Helena Vasconcelos.',
      hora: 'Hoje, 09:00',
      icone: Icons.calendar_today_outlined,
      categoria: 'Consultas',
      resolvido: false,
    ),
    _Alerta(
      titulo: 'Lembrete de hidratacao',
      descricao: 'Sr. Joaquim nao registra ingestao de agua ha mais de 2 horas. Oferecer um copo agora ajuda a manter o ritmo do dia.',
      hora: '19:45',
      icone: Icons.water_drop_outlined,
      categoria: 'Hidratacao',
      resolvido: false,
    ),
  ];

  static const List<_Alerta> _resolvidos = [
    _Alerta(
      titulo: 'Pressao arterial dentro do esperado',
      descricao: 'Karina registrou 128 x 82 mmHg as 14:30.',
      hora: '14:30',
      icone: Icons.check_circle_outline,
      categoria: 'Vitais',
      resolvido: true,
    ),
    _Alerta(
      titulo: 'Rafael entrou no Circulo Familiar',
      descricao: 'Convite aceito. Papel definido como observador.',
      hora: 'Ontem',
      icone: Icons.check_circle_outline,
      categoria: 'Familia',
      resolvido: true,
    ),
    _Alerta(
      titulo: 'Metformina das 19h confirmada',
      descricao: 'Karina registrou a confirmacao as 19:00.',
      hora: '19:00',
      icone: Icons.check_circle_outline,
      categoria: 'Medicamentos',
      resolvido: true,
    ),
  ];

  List<_Alerta> _filtrar(List<_Alerta> lista) {
    if (_filtroSelecionado == 'Todas') return lista;
    return lista.where((a) => a.categoria == _filtroSelecionado).toList();
  }

  @override
  Widget build(BuildContext context) {
    final atencaoFiltrado = _filtrar(_atencao);
    final resolvidosFiltrado = _filtrar(_resolvidos);

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
              if (atencaoFiltrado.isNotEmpty) ...[
                _buildSecaoAlertas(
                  context,
                  titulo: 'Atencao (${atencaoFiltrado.length})',
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
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cuidando de Sr. Joaquim',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text('Alertas da Familia',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 2),
        Text('Pendencias e itens resolvidos.',
            style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildFiltros(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filtros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selecionado = _filtros[i] == _filtroSelecionado;
          return GestureDetector(
            onTap: () => setState(() => _filtroSelecionado = _filtros[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selecionado ? AppTheme.primary : AppTheme.cardNormal,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selecionado ? AppTheme.primary : AppTheme.cardBorder,
                ),
              ),
              child: Text(
                _filtros[i],
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selecionado
                          ? Colors.white
                          : AppTheme.textSecondary,
                      fontWeight: selecionado
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecaoAlertas(BuildContext context,
      {required String titulo, required List<_Alerta> alertas}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...alertas.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildCardAlerta(context, a),
            )),
      ],
    );
  }

  Widget _buildCardAlerta(BuildContext context, _Alerta alerta) {
    final corIcone = alerta.resolvido ? Colors.green : AppTheme.primary;
    final corFundo = alerta.resolvido
        ? Colors.green.shade50
        : AppTheme.cardNormal;
    final corBorda =
        alerta.resolvido ? Colors.green.shade200 : AppTheme.cardBorder;

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
                Text(alerta.titulo,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                const SizedBox(height: 4),
                Text(alerta.descricao,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(alerta.hora,
                    style: Theme.of(context).textTheme.labelMedium),
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
