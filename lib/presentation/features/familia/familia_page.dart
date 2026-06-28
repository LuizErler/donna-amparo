import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FamiliaPage extends StatelessWidget {
  const FamiliaPage({super.key});

  static const List<_Membro> _membros = [
    _Membro(iniciais: 'KM', nome: 'Karina Mendes', papel: 'Filha · Cuidadora principal', status: 'Ativa agora', isPrincipal: true, cor: Color(0xFFC1622A)),
    _Membro(iniciais: 'RM', nome: 'Rafael Mendes', papel: 'Filho · Observador', status: 'Ha 2 horas', isPrincipal: false, cor: Color(0xFF7A5C44)),
    _Membro(iniciais: 'LM', nome: 'Luiza Mendes', papel: 'Neta · Observadora', status: 'Ativa agora', isPrincipal: false, cor: Color(0xFF5C8A6E)),
    _Membro(iniciais: 'DC', nome: 'Dona Cecilia', papel: 'Esposa · Cuidadora', status: 'Ontem as 21:40', isPrincipal: false, cor: Color(0xFF6B7A8D)),
  ];

  static const List<_Atividade> _atividades = [
    _Atividade(autor: 'Karina', acao: 'registrou a pressao arterial (128 x 82)', hora: '14:30'),
    _Atividade(autor: 'Sr. Joaquim', acao: 'confirmou Losartana das 08:00', hora: '06:05'),
    _Atividade(autor: 'Rafael', acao: 'adicionou consulta com Dr. Augusto', hora: 'Ontem, 18:12'),
    _Atividade(autor: 'Luiza', acao: 'deixou um recado na agenda', hora: 'Ontem, 12:00'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Circulo Familiar'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quem esta acompanhando o Sr. Joaquim.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _buildCardConvite(context),
              const SizedBox(height: 28),
              _buildMembros(context),
              const SizedBox(height: 28),
              _buildAtividade(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardConvite(BuildContext context) {
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
          Text('Convide alguem da familia',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  )),
          const SizedBox(height: 6),
          Text('Compartilhe o cuidado com mais pessoas de confianca.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70)),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add_outlined,
                    size: 14, color: Colors.white),
                label: const Text('Convidar por e-mail',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.link, size: 14, color: Colors.white),
                label: const Text('Copiar link',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembros(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Membros', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ..._membros.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildCardMembro(context, m),
            )),
      ],
    );
  }

  Widget _buildCardMembro(BuildContext context, _Membro m) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardNormal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: m.cor,
            child: Text(m.iniciais,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(m.nome,
                        style: Theme.of(context).textTheme.titleMedium),
                    if (m.isPrincipal) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('PRINCIPAL',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                )),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(m.papel,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: m.status.contains('agora')
                            ? Colors.green
                            : AppTheme.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(m.status,
                        style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtividade(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Atividade da familia',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ..._atividades.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardNormal,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.show_chart,
                          color: AppTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${a.autor} ',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(
                              text: a.acao,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(a.hora,
                        style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _Membro {
  final String iniciais;
  final String nome;
  final String papel;
  final String status;
  final bool isPrincipal;
  final Color cor;
  const _Membro({
    required this.iniciais,
    required this.nome,
    required this.papel,
    required this.status,
    required this.isPrincipal,
    required this.cor,
  });
}

class _Atividade {
  final String autor;
  final String acao;
  final String hora;
  const _Atividade(
      {required this.autor, required this.acao, required this.hora});
}
