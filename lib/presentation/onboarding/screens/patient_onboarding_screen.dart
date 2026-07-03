import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/patient/repositories/patient_repository.dart';
import '../providers/onboarding_providers.dart';

class PatientOnboardingScreen extends ConsumerStatefulWidget {
  const PatientOnboardingScreen({super.key});

  @override
  ConsumerState<PatientOnboardingScreen> createState() =>
      _PatientOnboardingScreenState();
}

class _PatientOnboardingScreenState
    extends ConsumerState<PatientOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _emergenciaController = TextEditingController();
  DateTime? _dataNascimento;

  @override
  void dispose() {
    _nomeController.dispose();
    _alergiasController.dispose();
    _emergenciaController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(now.year - 75),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
      helpText: 'Data de nascimento',
    );
    if (picked != null) {
      setState(() => _dataNascimento = picked);
    }
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataNascimento == null) {
      _showError('Informe a data de nascimento.');
      return;
    }

    final error = await ref.read(onboardingControllerProvider.notifier).submit(
          CreatePatientInput(
            fullName: _nomeController.text.trim(),
            dateOfBirth: _dataNascimento!,
            allergies: _alergiasController.text.trim().isEmpty
                ? null
                : _alergiasController.text.trim(),
            emergencyContact: _emergenciaController.text.trim().isEmpty
                ? null
                : _emergenciaController.text.trim(),
          ),
        );

    if (!mounted) return;
    if (error != null) {
      _showError(error);
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

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(onboardingControllerProvider).isLoading;
    final cardColor = AppTheme.cardSurface(context);
    final borderColor = AppTheme.cardOutline(context);
    final dateLabel = _dataNascimento == null
        ? 'Selecionar data'
        : _formatDate(_dataNascimento!);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cadastrar paciente',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 6),
                Text(
                  'Quem você vai acompanhar no Donna Amparo?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                _buildCampo(
                  context,
                  label: 'Nome completo',
                  hint: 'Ex.: Joaquim Silva',
                  controller: _nomeController,
                  icone: Icons.person_outline,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 14),
                _buildDataNascimento(
                  context,
                  label: dateLabel,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  onTap: _selecionarData,
                ),
                const SizedBox(height: 14),
                _buildCampo(
                  context,
                  label: 'Alergias conhecidas (opcional)',
                  hint: 'Ex.: dipirona, amendoim',
                  controller: _alergiasController,
                  icone: Icons.warning_amber_outlined,
                  cardColor: cardColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 14),
                _buildCampo(
                  context,
                  label: 'Contato de emergencia (opcional)',
                  hint: 'Nome e telefone',
                  controller: _emergenciaController,
                  icone: Icons.phone_outlined,
                  cardColor: cardColor,
                  borderColor: borderColor,
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
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Concluir cadastro',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.white),
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

  Widget _buildDataNascimento(
    BuildContext context, {
    required String label,
    required Color cardColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data de nascimento',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: cardColor,
              prefixIcon: Icon(Icons.calendar_today_outlined,
                  color: AppTheme.onSurfaceSecondary(context), size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
      ],
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
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: _inputDecoration(
            context,
            hint,
            icone,
            cardColor,
            borderColor,
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
    Color borderColor,
  ) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: borderColor),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: Theme.of(context).textTheme.bodyMedium,
      filled: true,
      fillColor: cardColor,
      prefixIcon: Icon(icone, color: AppTheme.onSurfaceSecondary(context), size: 20),
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
