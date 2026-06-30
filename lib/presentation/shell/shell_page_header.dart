import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/configuracoes/configuracoes_page.dart';
import '../features/familia/familia_page.dart';
import '../../core/theme/app_theme.dart';
import '../care/providers/care_providers.dart';

/// Avatar do menu superior — abre o hub Perfil.
class ProfileAvatarButton extends ConsumerWidget {
  const ProfileAvatarButton({super.key, this.initials});

  final String? initials;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careAsync = ref.watch(careContextProvider);
    final String displayInitials = initials ??
        careAsync.maybeWhen(
          data: (ctx) => ctx.profileInitials,
          orElse: () => '?',
        );

    return GestureDetector(
      onTap: () => openPerfil(context),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: AppTheme.primary,
        child: Text(
          displayInitials,
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
class ShellPageHeader extends ConsumerWidget {
  const ShellPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.contextLabel,
    this.showProfileButton = true,
  });

  final String title;
  final String? subtitle;
  final String? contextLabel;
  final bool showProfileButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careAsync = ref.watch(careContextProvider);
    final String resolvedContext = contextLabel ??
        careAsync.maybeWhen(
          data: (ctx) => ctx.contextLabel,
          orElse: () => 'Carregando contexto...',
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(resolvedContext,
                  style: Theme.of(context).textTheme.bodyMedium),
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
