import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/care_team/repositories/care_team_repository_impl.dart';
import '../../../domain/care_team/care_team_role.dart';
import '../../../domain/care_team/entities/care_invite_result.dart';
import '../providers/care_team_providers.dart';

enum InviteShareMode { form, qrCode }

Future<void> showInviteMemberSheet(
  BuildContext context,
  WidgetRef ref, {
  required String patientId,
  InviteShareMode mode = InviteShareMode.form,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _InviteMemberSheet(
      patientId: patientId,
      mode: mode,
    ),
  );
}

class _InviteMemberSheet extends ConsumerStatefulWidget {
  const _InviteMemberSheet({
    required this.patientId,
    required this.mode,
  });

  final String patientId;
  final InviteShareMode mode;

  @override
  ConsumerState<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<_InviteMemberSheet> {
  CareTeamRole _role = CareTeamRole.caregiver;
  bool _loading = false;
  CareInviteResult? _lastInvite;
  String? _lastInviteLink;

  bool get _isQrMode => widget.mode == InviteShareMode.qrCode;

  Future<void> _createInvite({required bool openShareSheet}) async {
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
        _lastInviteLink = link;
        _loading = false;
      });

      if (openShareSheet) {
        await _shareInvite(link, result);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _shareInvite(String link, CareInviteResult result) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      _inviteShareMessage(link, result),
      subject: 'Convite Donna Amparo',
      sharePositionOrigin: box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null,
    );
  }

  Future<void> _shareLastLink() async {
    final invite = _lastInvite;
    final link = _lastInviteLink;
    if (invite == null || link == null) return;
    await _shareInvite(link, invite);
  }

  Future<void> _copyLastLink() async {
    final link = _lastInviteLink;
    if (link == null) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    _showSnack('Link copiado!');
  }

  String _inviteShareMessage(String link, CareInviteResult result) {
    return 'Voce foi convidado(a) para acompanhar o cuidado no Donna Amparo '
        'como ${_role.label}.\n\n'
        'Valido ate ${_formatDate(result.expiresAt)}.\n\n'
        'Aceite o convite pelo link:\n$link';
  }

  void _onRoleSelected(CareTeamRole role) {
    setState(() {
      _role = role;
      _lastInvite = null;
      _lastInviteLink = null;
    });
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
          Text(
            _isQrMode ? 'Convite por QR Code' : 'Convidar membro',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _isQrMode
                ? 'Escolha o papel e mostre o QR Code para a pessoa escanear. Expira em 7 dias.'
                : 'Escolha o papel e compartilhe via WhatsApp ou outro app. Expira em 7 dias.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'Papel no cuidado',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CareTeamRepositoryImpl.inviteableRoles.map((role) {
              final selected = _role == role;
              return ChoiceChip(
                label: Text(role.label),
                selected: selected,
                onSelected:
                    _loading ? null : (_) => _onRoleSelected(role),
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
          if (_isQrMode && _lastInviteLink != null) ...[
            _buildQrSection(context),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _copyLastLink,
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Copiar link do convite'),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _loading
                    ? null
                    : () => _createInvite(openShareSheet: !_isQrMode),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isQrMode ? Icons.qr_code : Icons.share,
                        size: 18,
                      ),
                label: Text(
                  _isQrMode ? 'Gerar QR Code' : 'Compartilhar convite',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          if (!_isQrMode && _lastInvite != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareLastLink,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Compartilhar novamente'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyLastLink,
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Copiar link'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildQrSection(BuildContext context) {
    final invite = _lastInvite!;
    final link = _lastInviteLink!;

    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: QrImageView(
              data: link,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppTheme.textPrimary,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Valido ate ${_formatDate(invite.expiresAt)} · ${_role.label}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Peça para escanear com a camera do celular.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
