import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/care_team/repositories/care_team_repository_impl.dart';
import '../../../domain/care_team/care_team_role.dart';
import '../../../domain/care_team/entities/care_team_member.dart';
import '../providers/care_team_providers.dart';

Future<void> showManageMemberSheet(
  BuildContext context,
  WidgetRef ref, {
  required String patientId,
  required CareTeamMember member,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _ManageMemberSheet(
      patientId: patientId,
      member: member,
    ),
  );
}

class _ManageMemberSheet extends ConsumerStatefulWidget {
  const _ManageMemberSheet({
    required this.patientId,
    required this.member,
  });

  final String patientId;
  final CareTeamMember member;

  @override
  ConsumerState<_ManageMemberSheet> createState() => _ManageMemberSheetState();
}

class _ManageMemberSheetState extends ConsumerState<_ManageMemberSheet> {
  late CareTeamRole _role;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _role = widget.member.role;
  }

  Future<void> _saveRole() async {
    if (_role == widget.member.role) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(careTeamRepositoryProvider).updateMemberRole(
            patientId: widget.patientId,
            profileId: widget.member.profileId,
            newRole: _role,
          );
      ref.invalidate(familyMembersProvider);
      ref.invalidate(currentCareRoleProvider);
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Papel atualizado para ${_role.label}.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _confirmRemove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover membro'),
        content: Text(
          'Remover ${widget.member.fullName} do circulo de cuidado? '
          'Essa pessoa perdera o acesso ao paciente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(careTeamRepositoryProvider).removeMember(
            patientId: widget.patientId,
            profileId: widget.member.profileId,
          );
      ref.invalidate(familyMembersProvider);
      ref.invalidate(currentCareRoleProvider);
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('${widget.member.fullName} removido(a).');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack(e.toString(), isError: true);
    }
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

  String _roleDescription(CareTeamRole role) {
    switch (role) {
      case CareTeamRole.caregiver:
        return 'Cadastra consultas, medicamentos e registra cuidados.';
      case CareTeamRole.caregiverBasic:
        return 'Marca doses e registra vitais.';
      case CareTeamRole.observer:
        return 'Somente leitura do cuidado.';
      default:
        return role.label;
    }
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
          Text('Gerenciar membro',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(widget.member.fullName,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Text('Papel no cuidado',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CareTeamRepositoryImpl.editableRoles.map((role) {
              return ChoiceChip(
                label: Text(role.label),
                selected: _role == role,
                onSelected: _loading
                    ? null
                    : (_) => setState(() => _role = role),
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _roleDescription(_role),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _saveRole,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Salvar papel'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _confirmRemove,
              icon: const Icon(Icons.person_remove_outlined, size: 18),
              label: const Text('Remover da familia'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
