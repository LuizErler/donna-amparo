import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/care_team/repositories/care_team_repository_impl.dart';
import '../../../domain/care_team/care_team_role.dart';
import '../../../domain/care_team/entities/care_invite_result.dart';
import '../providers/care_team_providers.dart';

Future<void> showInviteMemberSheet(
  BuildContext context,
  WidgetRef ref, {
  required String patientId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _InviteMemberSheet(patientId: patientId),
  );
}

class _InviteMemberSheet extends ConsumerStatefulWidget {
  const _InviteMemberSheet({required this.patientId});

  final String patientId;

  @override
  ConsumerState<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<_InviteMemberSheet> {
  CareTeamRole _role = CareTeamRole.caregiver;
  bool _loading = false;
  CareInviteResult? _lastInvite;

  Future<void> _createInvite({required bool copyToClipboard}) async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(careTeamRepositoryProvider).createInvite(
            patientId: widget.patientId,
            role: _role,
          );
      final link =
          ref.read(careTeamRepositoryProvider).buildInviteLink(result.token);

      if (!mounted) return;
      setState(() {
        _lastInvite = result;
        _loading = false;
      });

      if (copyToClipboard) {
        await Clipboard.setData(ClipboardData(text: link));
        if (!mounted) return;
        _showSnack('Link copiado! Valido ate ${_formatDate(result.expiresAt)}.');
      } else {
        _showSnack('Convite criado. Copie o link abaixo.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _copyLastLink() async {
    final invite = _lastInvite;
    if (invite == null) return;
    final link =
        ref.read(careTeamRepositoryProvider).buildInviteLink(invite.token);
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    _showSnack('Link copiado!');
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Convidar membro',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Escolha o papel e compartilhe o link. O convite expira em 7 dias.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text('Papel no cuidado',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CareTeamRepositoryImpl.inviteableRoles.map((role) {
              final selected = _role == role;
              return ChoiceChip(
                label: Text(role.label),
                selected: selected,
                onSelected: _loading
                    ? null
                    : (_) => setState(() => _role = role),
              );
            }).toList(),
          ),
          if (_role == CareTeamRole.caregiver || _role == CareTeamRole.observer)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _roleDescription(_role),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : () => _createInvite(copyToClipboard: true),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.link, size: 18),
              label: const Text('Copiar link de convite'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (_lastInvite != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _copyLastLink,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copiar ultimo link gerado'),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _roleDescription(CareTeamRole role) {
    switch (role) {
      case CareTeamRole.caregiver:
        return 'Registra doses, consultas e alertas.';
      case CareTeamRole.observer:
        return 'Somente leitura do cuidado.';
      default:
        return role.label;
    }
  }
}
