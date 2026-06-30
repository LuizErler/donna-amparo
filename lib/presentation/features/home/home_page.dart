import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../care/providers/care_providers.dart';
import '../../shell/shell_page_header.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careAsync = ref.watch(careContextProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, careAsync),
              const SizedBox(height: 24),
              _buildCardProximoMedicamento(context),
              const SizedBox(height: 24),
              _buildHidratacao(context, careAsync),
              const SizedBox(height: 24),
              _buildProximaConsulta(context),
              const SizedBox(height: 24),
              _buildPendenciasFamilia(context),
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
        subtitle: 'Veja como esta o dia de ${ctx.patientName}.',
      ),
    );
  }

  Widget _buildCardProximoMedicamento(BuildContext context) {
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
              Text('Proximo medicamento',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      )),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.medication_outlined,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Losartana 50 mg',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 4),
          Text('as 20:00',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirmar dose'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHidratacao(BuildContext context, AsyncValue<CareContext> careAsync) {
    final patientName = careAsync.maybeWhen(
      data: (ctx) => ctx.patientName,
      orElse: () => 'paciente',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardNormal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
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
                child: const Icon(Icons.water_drop_outlined,
                    color: Colors.blue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hidratacao',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('Ultimo registro ha 145 min',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Faz 145 minutos desde a ultima agua. Hora de oferecer um copo ao $patientName.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Registrar agua'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Lembrete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProximaConsulta(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Proxima consulta',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardNormal,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
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
                    Text('Cardiologista — Dr. Mendes',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('Quinta, 15:30 · Hospital Sao Lucas',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).textTheme.bodyMedium?.color),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendenciasFamilia(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pendencias da familia',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildPendencia(
          context,
          icone: Icons.medication_outlined,
          titulo: 'Medicamento das 20h',
          descricao:
              'O paciente ainda nao tomou o medicamento das 20h. Alguem pode verificar?',
          cor: Colors.orange,
        ),
        const SizedBox(height: 10),
        _buildPendencia(
          context,
          icone: Icons.water_drop_outlined,
          titulo: 'Hidratacao',
          descricao: 'Paciente nao registra agua ha mais de 2 horas.',
          cor: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildPendencia(
    BuildContext context, {
    required IconData icone,
    required String titulo,
    required String descricao,
    required Color cor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNormal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
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
