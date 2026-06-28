import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../shell/shell_page_header.dart';

class MedicamentosPage extends StatefulWidget {
  const MedicamentosPage({super.key});

  @override
  State<MedicamentosPage> createState() => _MedicamentosPageState();
}

class _MedicamentosPageState extends State<MedicamentosPage> {
  final List<_Medicamento> _medicamentos = [
    _Medicamento(nome: 'Losartana 50 mg', instrucao: 'Com agua, apos refeicao', hora: '08:00', periodo: 'Manha', tomou: true),
    _Medicamento(nome: 'Metformina 500 mg', instrucao: 'Durante o cafe da manha', hora: '08:00', periodo: 'Manha', tomou: true),
    _Medicamento(nome: 'AAS 100 mg', instrucao: 'Com agua', hora: '12:00', periodo: 'Tarde', tomou: true),
    _Medicamento(nome: 'Metformina 500 mg', instrucao: 'Durante o almoco', hora: '12:00', periodo: 'Tarde', tomou: false),
    _Medicamento(nome: 'Atorvastatina 20 mg', instrucao: 'Preferencialmente a noite', hora: '20:00', periodo: 'Noite', tomou: false),
    _Medicamento(nome: 'Losartana 50 mg', instrucao: 'Com agua, apos jantar', hora: '20:00', periodo: 'Noite', tomou: false),
    _Medicamento(nome: 'Clonazepam 0.5 mg', instrucao: 'Antes de dormir', hora: '22:00', periodo: 'Noite', tomou: false),
  ];

  void _toggleTomou(int index) {
    setState(() {
      _medicamentos[index].tomou = !_medicamentos[index].tomou;
    });
  }

  List<_Medicamento> get _manha =>
      _medicamentos.where((m) => m.periodo == 'Manha').toList();
  List<_Medicamento> get _tarde =>
      _medicamentos.where((m) => m.periodo == 'Tarde').toList();
  List<_Medicamento> get _noite =>
      _medicamentos.where((m) => m.periodo == 'Noite').toList();

  int get _totalTomados => _medicamentos.where((m) => m.tomou).length;
  int get _total => _medicamentos.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildProgresso(context),
              const SizedBox(height: 28),
              _buildPeriodo(context, 'Manha', Icons.wb_sunny_outlined, _manha),
              const SizedBox(height: 20),
              _buildPeriodo(context, 'Tarde', Icons.wb_cloudy_outlined, _tarde),
              const SizedBox(height: 20),
              _buildPeriodo(context, 'Noite', Icons.nightlight_outlined, _noite),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Adicionar medicamento',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const ShellPageHeader(
      title: 'Medicamentos',
      subtitle: 'Doses do dia e confirmacoes.',
    );
  }

  Widget _buildProgresso(BuildContext context) {
    final double pct = _totalTomados / _total;
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
              Text('$_totalTomados de $_total doses',
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
                : '${_total - _totalTomados} doses pendentes para hoje.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodo(BuildContext context, String titulo, IconData icone,
      List<_Medicamento> lista) {
    final todosTomados = lista.every((m) => m.tomou);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            if (todosTomados)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Completo',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        )),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ...lista.asMap().entries.map((entry) {
          final globalIndex = _medicamentos.indexOf(entry.value);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCardMedicamento(context, entry.value, globalIndex),
          );
        }),
      ],
    );
  }

  Widget _buildCardMedicamento(
      BuildContext context, _Medicamento med, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: med.tomou
            ? Colors.green.shade50
            : AppTheme.cardNormal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: med.tomou ? Colors.green.shade200 : AppTheme.cardBorder,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleTomou(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: med.tomou ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: med.tomou ? Colors.green : AppTheme.cardBorder,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: med.tomou
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
                  med.nome,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: med.tomou
                            ? TextDecoration.lineThrough
                            : null,
                        color: med.tomou
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  med.instrucao,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: med.tomou
                            ? AppTheme.textSecondary.withValues(alpha: 0.7)
                            : null,
                      ),
                ),
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
                  color: med.tomou
                      ? Colors.green.shade100
                      : AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  med.hora,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: med.tomou
                            ? Colors.green.shade700
                            : AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                med.tomou ? 'Confirmado' : 'Pendente',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: med.tomou
                          ? Colors.green.shade600
                          : AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Medicamento {
  final String nome;
  final String instrucao;
  final String hora;
  final String periodo;
  bool tomou;

  _Medicamento({
    required this.nome,
    required this.instrucao,
    required this.hora,
    required this.periodo,
    required this.tomou,
  });
}
