import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../configuracoes/configuracoes_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
              const SizedBox(height: 24),
              _buildCardProximoMedicamento(context),
              const SizedBox(height: 24),
              _buildHidratacao(context),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cuidando de Sr. Joaquim',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text('Bom dia, Karina',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 2),
              Text('Veja como esta o dia do Sr. Joaquim.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ConfiguracoesPage()),
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primary,
            child: const Text(
              'K',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
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
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.open_in_new, size: 14, color: Colors.white),
            label: const Text('Confirmar agora',
                style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHidratacao(BuildContext context) {
    const double atual = 900;
    const double meta = 1800;
    const double progresso = atual / meta;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNormal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.water_drop_outlined,
                        color: AppTheme.primary, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('900 ml de 1800 ml',
                          style:
                              Theme.of(context).textTheme.titleMedium),
                      Text('Ultima ingestao registrada as 17:20',
                          style:
                              Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 14),
                label: const Text('200 ml',
                    style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 8,
              backgroundColor: AppTheme.cardBorder,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.notifications_outlined,
                  size: 14, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Faz 145 minutos desde a ultima agua. Hora de oferecer um copo ao Sr. Joaquim.',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.primary,
                      ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Proxima consulta',
                style: Theme.of(context).textTheme.titleMedium),
            Text('Ver todas',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    )),
          ],
        ),
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
                child: const Icon(Icons.calendar_today,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cardiologia',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('Dra. Helena Vasconcelos',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text('Quinta, 19 de junho · 10:30',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                  Text('Clinica CorVida — Sala 304',
                      style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendenciasFamilia(BuildContext context) {
    final pendencias = [
      _Pendencia(
        titulo: 'Losartana das 20h ainda nao confirmada',
        descricao:
            'O Sr. Joaquim ainda nao tomou o medicamento das 20h. Alguem pode verificar?',
        hora: '20:42',
        icone: Icons.medication_outlined,
      ),
      _Pendencia(
        titulo: 'Consulta de Cardiologia se aproxima',
        descricao:
            'Quinta, 19 de junho as 10:30 com a Dra. Helena Vasconcelos.',
        hora: 'Hoje, 09:00',
        icone: Icons.calendar_today_outlined,
      ),
      _Pendencia(
        titulo: 'Lembrete de hidratacao',
        descricao: 'Sr. Joaquim nao registra agua ha mais de 2 horas.',
        hora: '19:45',
        icone: Icons.water_drop_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pendencias da familia',
                style: Theme.of(context).textTheme.titleMedium),
            Text('Ver tudo',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    )),
          ],
        ),
        const SizedBox(height: 12),
        ...pendencias.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
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
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(p.icone,
                          color: AppTheme.primary, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.titulo,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(p.descricao,
                              style:
                                  Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text(p.hora,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _Pendencia {
  final String titulo;
  final String descricao;
  final String hora;
  final IconData icone;
  _Pendencia(
      {required this.titulo,
      required this.descricao,
      required this.hora,
      required this.icone});
}
