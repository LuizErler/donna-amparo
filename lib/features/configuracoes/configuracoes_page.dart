import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardDark : AppTheme.cardNormal;
    final cardBorderColor = isDark ? AppTheme.cardBorderDark : AppTheme.cardBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuracoes'),
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
            const SizedBox(height: 28),
            _buildSecaoSobre(context, cardColor, cardBorderColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoPerfil(BuildContext context, Color cardColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Perfil', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
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
                child: Text('K',
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
                    Text('Karina Mendes',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text('Filha · Cuidadora principal',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
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
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).textTheme.bodyMedium?.color),
            ],
          ),
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
          titulo: 'Privacidade e seguranca',
          subtitulo: 'Senha, biometria e dados',
          onTap: () {},
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
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (_, mode, __) {
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
                              onTap: () => themeNotifier.value =
                                  ThemeMode.system,
                            ),
                            const SizedBox(width: 8),
                            _buildThemeChip(
                              context,
                              label: 'Claro',
                              icone: Icons.light_mode,
                              selecionado: isManualLight,
                              onTap: () => themeNotifier.value =
                                  ThemeMode.light,
                            ),
                            const SizedBox(width: 8),
                            _buildThemeChip(
                              context,
                              label: 'Escuro',
                              icone: Icons.dark_mode,
                              selecionado: isManualDark,
                              onTap: () => themeNotifier.value =
                                  ThemeMode.dark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              Divider(height: 1, color: borderColor),
              _buildItemSemContainer(
                context,
                icone: Icons.language_outlined,
                titulo: 'Idioma',
                subtitulo: 'Portugues (Brasil)',
                onTap: () {},
              ),
              Divider(height: 1, color: borderColor),
              _buildItemSemContainer(
                context,
                icone: Icons.text_fields_outlined,
                titulo: 'Tamanho do texto',
                subtitulo: 'Padrao',
                onTap: () {},
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
              _buildItemSemContainer(
                context,
                icone: Icons.info_outline,
                titulo: 'Versao do app',
                subtitulo: '1.0.0',
                onTap: () {},
              ),
              Divider(height: 1, color: borderColor),
              _buildItemSemContainer(
                context,
                icone: Icons.help_outline,
                titulo: 'Ajuda e suporte',
                subtitulo: 'Central de ajuda e contato',
                onTap: () {},
              ),
              Divider(height: 1, color: borderColor),
              _buildItemSemContainer(
                context,
                icone: Icons.logout,
                titulo: 'Sair',
                subtitulo: 'Encerrar sessao',
                onTap: () {},
                cor: Colors.red.shade400,
              ),
            ],
          ),
        ),
      ],
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
