import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ConsultasPage extends StatelessWidget {
  const ConsultasPage({super.key});

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
              const SizedBox(height: 28),
              _buildSection(
                context,
                titulo: 'Proximas',
                children: [
                  _buildCardDestaque(context),
                  const SizedBox(height: 12),
                  _buildCardNormal(
                    context,
                    especialidade: 'Geriatria',
                    medico: 'Dr. Augusto Ramires',
                    data: 'Terca, 1 de julho · 14:00',
                    local: 'Consultorio particular — Rua das Acacias, 220',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildSection(
                context,
                titulo: 'Historico',
                children: [
                  _buildCardHistorico(
                    context,
                    especialidade: 'Oftalmologia',
                    medico: 'Dra. Marta Yoshida',
                    data: '10 de maio · 09:00',
                    local: 'Hospital Sao Lucas',
                    anotacao: 'Ajustar grau dos oculos. Retorno em 6 meses.',
                  ),
                  const SizedBox(height: 12),
                  _buildCardHistorico(
                    context,
                    especialidade: 'Endocrinologia',
                    medico: 'Dr. Pedro Salim',
                    data: '22 de abril · 16:30',
                    local: 'Clinica Endolife',
                    anotacao: 'Manter Metformina. Solicitada hemoglobina glicada.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
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
        Text('Consultas', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 2),
        Text('Agenda medica e historico.',
            style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildSection(BuildContext context,
      {required String titulo, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildCardDestaque(BuildContext context) {
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
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text('Cardiologia',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          )),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('PROXIMA',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        )),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Dra. Helena Vasconcelos',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text('Quinta, 19 de junho · 10:30',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      )),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text('Clinica CorVida — Sala 304',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Levar exames de sangue recentes.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardNormal(
    BuildContext context, {
    required String especialidade,
    required String medico,
    required String data,
    required String local,
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
                Text(especialidade,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(medico,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(data,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        )),
                const SizedBox(height: 2),
                Text(local,
                    style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHistorico(
    BuildContext context, {
    required String especialidade,
    required String medico,
    required String data,
    required String local,
    required String anotacao,
  }) {
    return Container(
      width: double.infinity,
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
                Text(especialidade,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(medico,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text('$data · $local',
                    style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
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
                    Text('ANOTACOES',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                )),
                  ],
                ),
                const SizedBox(height: 6),
                Text(anotacao,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
