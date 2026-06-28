import 'package:flutter/material.dart';

import '../features/configuracoes/configuracoes_page.dart';
import '../features/familia/familia_page.dart';
import '../../core/theme/app_theme.dart';

/// Avatar do menu superior — abre o hub Perfil.
class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({super.key, this.initials = 'K'});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openPerfil(context),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: AppTheme.primary,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

/// Cabecalho padrao das abas principais (contexto + titulo + avatar Perfil).
class ShellPageHeader extends StatelessWidget {
  const ShellPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.contextLabel = 'Cuidando de Sr. Joaquim',
    this.showProfileButton = true,
  });

  final String title;
  final String? subtitle;
  final String contextLabel;
  final bool showProfileButton;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(contextLabel, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (showProfileButton) ...[
          const SizedBox(width: 12),
          const ProfileAvatarButton(),
        ],
      ],
    );
  }
}

void openPerfil(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ConfiguracoesPage()),
  );
}

void openCirculoFamiliar(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const FamiliaPage()),
  );
}
