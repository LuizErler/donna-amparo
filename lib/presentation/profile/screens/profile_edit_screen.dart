import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/profile/entities/update_profile_input.dart';
import '../../care/providers/care_providers.dart';
import '../providers/profile_providers.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initFromProfile(WidgetRef ref) {
    if (_initialized) return;
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) return;
    _nomeController.text = profile.fullName;
    _telefoneController.text = profile.phone ?? '';
    _emailController.text = profile.email ?? '';
    _initialized = true;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final error = await ref.read(profileEditControllerProvider.notifier).save(
          UpdateProfileInput(
            fullName: _nomeController.text.trim(),
            phone: _telefoneController.text.trim(),
          ),
        );

    if (!mounted) return;
    if (error != null) {
      _showSnack(error, isError: true);
      return;
    }

    Navigator.pop(context);
    _showSnack('Perfil atualizado.');
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
    _initFromProfile(ref);

    final profileAsync = ref.watch(currentProfileProvider);
    final isLoading = ref.watch(profileEditControllerProvider).isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardDark : AppTheme.cardNormal;
    final borderColor = isDark ? AppTheme.cardBorderDark : AppTheme.cardBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Erro ao carregar perfil.')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Perfil nao encontrado.'));
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primary,
                        child: Text(
                          profile.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildCampo(
                      context,
                      label: 'Nome completo',
                      hint: 'Seu nome',
                      controller: _nomeController,
                      icone: Icons.person_outline,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Informe seu nome' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildCampo(
                      context,
                      label: 'E-mail',
                      controller: _emailController,
                      icone: Icons.email_outlined,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      readOnly: true,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'O e-mail da conta nao pode ser alterado aqui.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    _buildCampo(
                      context,
                      label: 'Telefone (opcional)',
                      hint: '(11) 99999-9999',
                      controller: _telefoneController,
                      icone: Icons.phone_outlined,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      tipoTeclado: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _salvar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppTheme.primary.withValues(alpha: 0.6),
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
                            : const Text('Salvar alteracoes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCampo(
    BuildContext context, {
    required String label,
    String? hint,
    required TextEditingController controller,
    required IconData icone,
    required Color cardColor,
    required Color borderColor,
    TextInputType? tipoTeclado,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: borderColor),
    );

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
          readOnly: readOnly,
          keyboardType: tipoTeclado,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: readOnly ? cardColor.withValues(alpha: 0.6) : cardColor,
            prefixIcon: Icon(icone, color: AppTheme.textSecondary, size: 20),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
