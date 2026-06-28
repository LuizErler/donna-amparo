import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (AppConfig.enableAuth && !_formKey.currentState!.validate()) return;

    if (!AppConfig.enableAuth) {
      await Future.delayed(const Duration(milliseconds: 400));
      return;
    }

    final error = await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _senhaController.text,
          fullName: _nomeController.text.trim(),
        );

    if (!mounted) return;
    if (error != null) {
      _showError(error);
      return;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardDark : AppTheme.cardNormal;
    final borderColor = isDark ? AppTheme.cardBorderDark : AppTheme.cardBorder;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Criar conta',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 6),
                Text('Junte-se ao Donna Amparo.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                _buildCampo(
                  context,
                  label: 'Nome completo',
                  hint: 'Karina Mendes',
                  controller: _nomeController,
                  icone: Icons.person_outline,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe seu nome' : null,
                ),
                const SizedBox(height: 14),
                _buildCampo(
                  context,
                  label: 'E-mail',
                  hint: 'seu@email.com',
                  controller: _emailController,
                  icone: Icons.email_outlined,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  tipoTeclado: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o e-mail';
                    if (!v.contains('@')) return 'E-mail invalido';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildCampoSenha(
                  context,
                  label: 'Senha',
                  hint: '••••••••',
                  controller: _senhaController,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe a senha';
                    if (v.length < 6) return 'Minimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildCampoSenha(
                  context,
                  label: 'Confirmar senha',
                  hint: '••••••••',
                  controller: _confirmarSenhaController,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  validator: (v) {
                    if (v != _senhaController.text) {
                      return 'As senhas nao conferem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _cadastrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppTheme.primary.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text('Criar conta',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Ja tem conta? ',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextSpan(
                            text: 'Entrar',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
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

  Widget _buildCampo(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icone,
    required Color cardColor,
    required Color borderColor,
    TextInputType? tipoTeclado,
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
        TextFormField(
          controller: controller,
          keyboardType: tipoTeclado,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: _inputDecoration(
              context, hint, icone, cardColor, borderColor),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCampoSenha(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required Color cardColor,
    required Color borderColor,
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
        TextFormField(
          controller: controller,
          obscureText: !_senhaVisivel,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: _inputDecoration(
            context, hint, Icons.lock_outline, cardColor, borderColor,
            sufixo: IconButton(
              icon: Icon(
                _senhaVisivel
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _senhaVisivel = !_senhaVisivel),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String hint,
    IconData icone,
    Color cardColor,
    Color borderColor, {
    Widget? sufixo,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: borderColor),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: Theme.of(context).textTheme.bodyMedium,
      filled: true,
      fillColor: cardColor,
      prefixIcon: Icon(icone, color: AppTheme.textSecondary, size: 20),
      suffixIcon: sufixo,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
