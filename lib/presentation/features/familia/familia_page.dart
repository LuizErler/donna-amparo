import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/care_team/entities/care_team_member.dart';
import '../../care/invite/invite_member_sheet.dart';
import '../../care/providers/care_providers.dart';
import '../../care/providers/care_team_providers.dart';

class FamiliaPage extends ConsumerWidget {
  const FamiliaPage({super.key});

  static const List<_Atividade> _atividades = [
    _Atividade(autor: 'Karina', acao: 'registrou a pressao arterial (128 x 82)', hora: '14:30'),
    _Atividade(autor: 'Sr. Joaquim', acao: 'confirmou Losartana das 08:00', hora: '06:05'),
    _Atividade(autor: 'Rafael', acao: 'adicionou consulta com Dr. Augusto', hora: 'Ontem, 18:12'),
    _Atividade(autor: 'Luiza', acao: 'deixou um recado na agenda', hora: 'Ontem, 12:00'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careAsync = ref.watch(careContextProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final roleAsync = ref.watch(currentCareRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Circulo Familiar'),
      ),
      body: SafeArea(
        child: careAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _buildError(context, 'Erro ao carregar contexto.'),
          data: (ctx) {
            final patient = ctx.patient;
            if (patient == null) {
              return _buildError(context, 'Nenhum paciente vinculado.');
            }

            final canInvite = roleAsync.maybeWhen(
              data: (role) => role?.canManageTeam ?? false,
              orElse: () => false,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quem esta acompanhando ${ctx.patientName}.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  if (canInvite)
                    _buildCardConvite(context, ref, patient.id)
                  else
                    _buildConviteSomenteLeitura(context),
                  const SizedBox(height: 28),
                  membersAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (_, _) => _buildError(context, 'Erro ao carregar membros.'),
                    data: (members) => _buildMembros(context, members),
                  ),
                  const SizedBox(height: 28),
                  _buildAtividade(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildConviteSomenteLeitura(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNormal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Text(
        'Somente o Cuidador Admin pode convidar novos membros.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildCardConvite(
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) {
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
                onPressed: () =>
                    showInviteMemberSheet(context, ref, patientId: patientId),
                icon: const Icon(Icons.person_add_outlined,
                    size: 14, color: Colors.white),
                label: const Text('Convidar membro',
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
                onPressed: () =>
                    showInviteMemberSheet(context, ref, patientId: patientId),
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

  Widget _buildMembros(BuildContext context, List<CareTeamMember> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Membros', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (members.isEmpty)
          Text('Nenhum membro encontrado.',
              style: Theme.of(context).textTheme.bodyMedium)
        else
          ...members.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildCardMembro(context, m),
              )),
      ],
    );
  }

  Widget _buildCardMembro(BuildContext context, CareTeamMember member) {
    final color = _memberColor(member.profileId);
    final status = member.isCurrentUser ? 'Voce' : 'Membro ativo';

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
            backgroundColor: color,
            child: Text(member.initials,
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
                    Expanded(
                      child: Text(member.fullName,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    if (member.isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('ADMIN',
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
                Text(member.role.label,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(status,
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

  Color _memberColor(String profileId) {
    const colors = [
      Color(0xFFC1622A),
      Color(0xFF7A5C44),
      Color(0xFF5C8A6E),
      Color(0xFF6B7A8D),
      Color(0xFF8B6BAE),
    ];
    return colors[profileId.hashCode.abs() % colors.length];
  }

  Widget _buildAtividade(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Atividade da familia',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Em breve — feed em tempo real.',
            style: Theme.of(context).textTheme.labelMedium),
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

class _Atividade {
  final String autor;
  final String acao;
  final String hora;
  const _Atividade(
      {required this.autor, required this.acao, required this.hora});
}
