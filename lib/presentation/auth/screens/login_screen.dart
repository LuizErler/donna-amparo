import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/accessibility/a11y.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_providers.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (AppConfig.enableAuth && !_formKey.currentState!.validate()) return;

    if (!AppConfig.enableAuth) {
      await Future.delayed(const Duration(milliseconds: 400));
      return;
    }

    final error = await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _senhaController.text,
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildLogo(context),
                const SizedBox(height: 48),
                _buildCampoEmail(context),
                const SizedBox(height: 14),
                _buildCampoSenha(context),
                const SizedBox(height: 12),
                _buildEsqueciSenha(context),
                const SizedBox(height: 28),
                _buildBotaoEntrar(context, isLoading),
                const SizedBox(height: 24),
                _buildDivisor(context),
                const SizedBox(height: 24),
                _buildBotaoGoogle(context),
                const SizedBox(height: 40),
                _buildRodape(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Donna Amparo',
                    style: Theme.of(context).textTheme.headlineMedium),
                Text('Cuidado familiar inteligente',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text('Bem-vinda de volta',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 6),
        Text('Entre com sua conta para continuar cuidando.',
            style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildCampoEmail(BuildContext context) {
    final cardColor = AppTheme.cardSurface(context);
    final borderColor = AppTheme.cardOutline(context);
    final iconColor = AppTheme.onSurfaceSecondary(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('E-mail',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'seu@email.com',
            hintStyle: Theme.of(context).textTheme.bodyMedium,
            filled: true,
            fillColor: cardColor,
            prefixIcon: Icon(Icons.email_outlined, color: iconColor, size: 20),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Informe o e-mail';
            if (!v.contains('@')) return 'E-mail inválido';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCampoSenha(BuildContext context) {
    final cardColor = AppTheme.cardSurface(context);
    final borderColor = AppTheme.cardOutline(context);
    final iconColor = AppTheme.onSurfaceSecondary(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Senha',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Semantics(
          label: 'Senha',
          obscured: !_senhaVisivel,
          child: TextFormField(
          controller: _senhaController,
          obscureText: !_senhaVisivel,
          autofillHints: const [AutofillHints.password],
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: Theme.of(context).textTheme.bodyMedium,
            filled: true,
            fillColor: cardColor,
            prefixIcon: Icon(Icons.lock_outline, color: iconColor, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _senhaVisivel
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: iconColor,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Informe a senha';
            if (v.length < 6) return 'Mínimo 6 caracteres';
            return null;
          },
        ),
        ),
      ],
    );
  }

  Widget _buildEsqueciSenha(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: MinTapTarget(
        semanticsLabel: 'Esqueci minha senha',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
        ),
        child: Text('Esqueci minha senha',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                )),
      ),
    );
  }

  Widget _buildBotaoEntrar(BuildContext context, bool isLoading) {
    return Semantics(
      button: true,
      label: 'Entrar na conta',
      child: SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : _entrar,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text('Entrar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    )),
      ),
    ),
    );
  }

  Widget _buildDivisor(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.cardOutline(context))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('ou', style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(child: Divider(color: AppTheme.cardOutline(context))),
      ],
    );
  }

  Widget _buildBotaoGoogle(BuildContext context) {
    final cardColor = AppTheme.cardSurface(context);
    final borderColor = AppTheme.cardOutline(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: cardColor,
          side: BorderSide(color: borderColor),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const Icon(Icons.g_mobiledata,
                  color: Colors.red, size: 22),
            ),
            const SizedBox(width: 10),
            Text('Entrar com Google',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildRodape(BuildContext context) {
    return Center(
      child: MinTapTarget(
        semanticsLabel: 'Não tem conta? Cadastre-se',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignupScreen()),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Não tem conta? ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextSpan(
                text: 'Cadastre-se',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
