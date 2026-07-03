import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_providers.dart';

/// Define nova senha (recuperacao por e-mail ou troca em Configuracoes).
class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.onSuccess,
  });

  final String titulo;
  final String subtitulo;
  final VoidCallback? onSuccess;

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (AppConfig.enableAuth && !_formKey.currentState!.validate()) return;

    final error = await ref.read(authControllerProvider.notifier).changePassword(
          newPassword: _senhaController.text,
        );

    if (!mounted) return;
    if (error != null) {
      _showSnack(error, isError: true);
      return;
    }

    if (widget.onSuccess != null) {
      widget.onSuccess!();
      return;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    _showSnack('Senha atualizada com sucesso.');
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

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final cardColor = AppTheme.cardSurface(context);
    final borderColor = AppTheme.cardOutline(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova senha'),
        automaticallyImplyLeading: widget.onSuccess == null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    widget.titulo,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitulo,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                _buildCampoSenha(
                  context,
                  label: 'Nova senha',
                  controller: _senhaController,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  semanticsLabel: 'Nova senha',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe a senha';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildCampoSenha(
                  context,
                  label: 'Confirmar senha',
                  controller: _confirmarController,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  semanticsLabel: 'Confirmar nova senha',
                  validator: (v) {
                    if (v != _senhaController.text) {
                      return 'As senhas não conferem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                Semantics(
                  button: true,
                  label: 'Salvar nova senha',
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Salvar senha'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCampoSenha(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required Color cardColor,
    required Color borderColor,
    required String semanticsLabel,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Semantics(
          label: semanticsLabel,
          obscured: !_senhaVisivel,
          child: TextFormField(
            controller: controller,
            obscureText: !_senhaVisivel,
            autofillHints: const [AutofillHints.newPassword],
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '••••••••',
              filled: true,
              fillColor: cardColor,
              prefixIcon: Icon(Icons.lock_outline,
                  color: AppTheme.onSurfaceSecondary(context), size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _senhaVisivel
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.onSurfaceSecondary(context),
                  size: 20,
                ),
                tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                onPressed: () =>
                    setState(() => _senhaVisivel = !_senhaVisivel),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
