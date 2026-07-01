import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/text_size_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/profile/entities/user_profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/screens/set_password_screen.dart';
import '../../care/providers/care_providers.dart';
import '../../care/providers/care_team_providers.dart';
import '../../profile/screens/profile_edit_screen.dart';
import '../../shell/shell_page_header.dart';

class ConfiguracoesPage extends ConsumerStatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  ConsumerState<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends ConsumerState<ConfiguracoesPage> {
  // Itens reservados para versoes futuras do app.
  static const _showLanguageOption = false;
  static const _showAppVersion = false;
  static const _showSupport = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardDark : AppTheme.cardNormal;
    final cardBorderColor = isDark ? AppTheme.cardBorderDark : AppTheme.cardBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecaoPerfil(context, cardColor, cardBorderColor),
            const SizedBox(height: 28),
            _buildSecaoSistema(context, isDark, cardColor, cardBorderColor),
            if (_showAppVersion || _showSupport) ...[
              const SizedBox(height: 28),
              _buildSecaoSobre(context, cardColor, cardBorderColor),
            ],
            const SizedBox(height: 32),
            _buildBotaoSair(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoPerfil(BuildContext context, Color cardColor, Color borderColor) {
    final profileAsync = ref.watch(currentProfileProvider);
    final roleAsync = ref.watch(currentCareRoleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Perfil', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        profileAsync.when(
          loading: () => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => _buildPerfilCard(
            context,
            cardColor,
            borderColor,
            initials: '?',
            nome: 'Perfil indisponivel',
            subtitulo: 'Tente novamente mais tarde',
            roleLabel: '—',
          ),
          data: (UserProfile? profile) {
            final roleLabel = roleAsync.maybeWhen(
              data: (role) => role?.label ?? 'Membro',
              orElse: () => 'Carregando...',
            );
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              ),
              child: _buildPerfilCard(
                context,
                cardColor,
                borderColor,
                initials: profile?.initials ?? '?',
                nome: profile?.fullName.isNotEmpty == true
                    ? profile!.fullName
                    : 'Cuidador',
                subtitulo: profile?.email ?? 'Conta Donna Amparo',
                roleLabel: roleLabel,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildItem(
          context,
          cardColor: cardColor,
          borderColor: borderColor,
          icone: Icons.people_outline,
          titulo: 'Circulo familiar',
          subtitulo: 'Membros, convites e papeis',
          onTap: () => openCirculoFamiliar(context),
        ),
        const SizedBox(height: 10),
        _buildItem(
          context,
          cardColor: cardColor,
          borderColor: borderColor,
          icone: Icons.notifications_outlined,
          titulo: 'Notificacoes',
          subtitulo: 'Alertas, lembretes e avisos',
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _buildItem(
          context,
          cardColor: cardColor,
          borderColor: borderColor,
          icone: Icons.lock_outline,
          titulo: 'Alterar senha',
          subtitulo: 'Atualize a senha da sua conta',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SetPasswordScreen(
                titulo: 'Alterar senha',
                subtitulo: 'Escolha uma nova senha segura para sua conta.',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoSistema(BuildContext context, bool isDark,
      Color cardColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sistema', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              // Toggle Dark Mode
              Consumer(
                builder: (context, ref, _) {
                  final mode = ref.watch(themeModeProvider);
                  final isManualDark = mode == ThemeMode.dark;
                  final isManualLight = mode == ThemeMode.light;
                  final isSystem = mode == ThemeMode.system;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.dark_mode
                                    : Icons.light_mode,
                                color: AppTheme.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Aparencia',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  Text(
                                    isSystem
                                        ? 'Seguindo o sistema'
                                        : isManualDark
                                            ? 'Modo escuro ativo'
                                            : 'Modo claro ativo',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Row(
                          children: [
                            _buildThemeChip(
                              context,
                              label: 'Sistema',
                              selecionado: isSystem,
                              onTap: () => ref
                                  .read(themeModeProvider.notifier)
                                  .state = ThemeMode.system,
                            ),
                            const SizedBox(width: 8),
                            _buildThemeChip(
                              context,
                              label: 'Claro',
                              icone: Icons.light_mode,
                              selecionado: isManualLight,
                              onTap: () => ref
                                  .read(themeModeProvider.notifier)
                                  .state = ThemeMode.light,
                            ),
                            const SizedBox(width: 8),
                            _buildThemeChip(
                              context,
                              label: 'Escuro',
                              icone: Icons.dark_mode,
                              selecionado: isManualDark,
                              onTap: () => ref
                                  .read(themeModeProvider.notifier)
                                  .state = ThemeMode.dark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (_showLanguageOption) ...[
                Divider(height: 1, color: borderColor),
                _buildItemSemContainer(
                  context,
                  icone: Icons.language_outlined,
                  titulo: 'Idioma',
                  subtitulo: 'Portugues (Brasil)',
                  onTap: () {},
                ),
              ],
              Divider(height: 1, color: borderColor),
              Consumer(
                builder: (context, ref, _) {
                  final textSize = ref.watch(textSizeProvider);
                  final isLarge = textSize == AppTextSize.large;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.text_fields_outlined,
                                color: AppTheme.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tamanho do texto',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(
                                    isLarge ? 'Texto ampliado' : 'Padrao',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Row(
                          children: [
                            _buildThemeChip(
                              context,
                              label: 'Padrao',
                              selecionado: !isLarge,
                              onTap: () => ref
                                  .read(textSizeProvider.notifier)
                                  .setSize(AppTextSize.standard),
                            ),
                            const SizedBox(width: 8),
                            _buildThemeChip(
                              context,
                              label: 'Grande',
                              icone: Icons.format_size,
                              selecionado: isLarge,
                              onTap: () => ref
                                  .read(textSizeProvider.notifier)
                                  .setSize(AppTextSize.large),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoSobre(BuildContext context, Color cardColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sobre', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              if (_showAppVersion) ...[
                _buildItemSemContainer(
                  context,
                  icone: Icons.info_outline,
                  titulo: 'Versao do app',
                  subtitulo: '1.0.0',
                  onTap: () {},
                ),
                if (_showSupport) Divider(height: 1, color: borderColor),
              ],
              if (_showSupport)
                _buildItemSemContainer(
                  context,
                  icone: Icons.help_outline,
                  titulo: 'Ajuda e suporte',
                  subtitulo: 'Central de ajuda e contato',
                  onTap: () {},
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoSair(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _sair,
        icon: Icon(Icons.logout, color: Colors.red.shade400, size: 20),
        label: Text(
          'Sair da conta',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red.shade400,
                fontWeight: FontWeight.w600,
              ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _sair() async {
    final error = await performSignOut(ref);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildPerfilCard(
    BuildContext context,
    Color cardColor,
    Color borderColor, {
    required String initials,
    required String nome,
    required String subtitulo,
    required String roleLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primary,
            child: Text(initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                )),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(subtitulo, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    roleLabel.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: Theme.of(context).textTheme.bodyMedium?.color),
        ],
      ),
    );
  }

  Widget _buildThemeChip(
    BuildContext context, {
    required String label,
    IconData? icone,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selecionado ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado ? AppTheme.primary : AppTheme.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone,
                  size: 13,
                  color: selecionado
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selecionado
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: selecionado
                          ? FontWeight.bold
                          : FontWeight.normal,
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required Color cardColor,
    required Color borderColor,
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitulo,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).textTheme.bodyMedium?.color),
          ],
        ),
      ),
    );
  }

  Widget _buildItemSemContainer(
    BuildContext context, {
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    Color? cor,
  }) {
    final corIcone = cor ?? AppTheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: corIcone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, color: corIcone, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: cor,
                          )),
                  Text(subtitulo,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).textTheme.bodyMedium?.color),
          ],
        ),
      ),
    );
  }
}
