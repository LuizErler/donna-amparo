import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../auth/cadastro_page.dart';
import '../../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _entrar() async {
    setState(() => _carregando = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _carregando = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardDark : AppTheme.cardNormal;
    final borderColor = isDark ? AppTheme.cardBorderDark : AppTheme.cardBorder;

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
                _buildCampoEmail(context, cardColor, borderColor),
                const SizedBox(height: 14),
                _buildCampoSenha(context, cardColor, borderColor),
                const SizedBox(height: 12),
                _buildEsqueciSenha(context),
                const SizedBox(height: 28),
                _buildBotaoEntrar(context),
                const SizedBox(height: 24),
                _buildDivisor(context),
                const SizedBox(height: 24),
                _buildBotaoGoogle(context, cardColor, borderColor),
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

  Widget _buildCampoEmail(
      BuildContext context, Color cardColor, Color borderColor) {
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
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'seu@email.com',
            hintStyle: Theme.of(context).textTheme.bodyMedium,
            filled: true,
            fillColor: cardColor,
            prefixIcon: Icon(Icons.email_outlined,
                color: AppTheme.textSecondary, size: 20),
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
            if (!v.contains('@')) return 'E-mail invalido';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCampoSenha(
      BuildContext context, Color cardColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Senha',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _senhaController,
          obscureText: !_senhaVisivel,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: Theme.of(context).textTheme.bodyMedium,
            filled: true,
            fillColor: cardColor,
            prefixIcon: Icon(Icons.lock_outline,
                color: AppTheme.textSecondary, size: 20),
            suffixIcon: IconButton(
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
            if (v.length < 6) return 'Minimo 6 caracteres';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEsqueciSenha(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {},
        child: Text('Esqueci minha senha',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                )),
      ),
    );
  }

  Widget _buildBotaoEntrar(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _carregando ? null : _entrar,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _carregando
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
    );
  }

  Widget _buildDivisor(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.cardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('ou',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(child: Divider(color: AppTheme.cardBorder)),
      ],
    );
  }

  Widget _buildBotaoGoogle(
      BuildContext context, Color cardColor, Color borderColor) {
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
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CadastroPage()),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Nao tem conta? ',
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
