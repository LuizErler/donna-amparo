import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/appointment/entities/appointment_visit_type.dart';
import '../../../domain/appointment/repositories/appointment_repository.dart';
import 'providers/appointment_providers.dart';

Future<bool?> showAddAppointmentSheet(
  BuildContext context,
  WidgetRef ref, {
  required String patientId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _AddAppointmentSheet(patientId: patientId),
  );
}

class _AddAppointmentSheet extends ConsumerStatefulWidget {
  const _AddAppointmentSheet({required this.patientId});

  final String patientId;

  @override
  ConsumerState<_AddAppointmentSheet> createState() =>
      _AddAppointmentSheetState();
}

class _AddAppointmentSheetState extends ConsumerState<_AddAppointmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _specialtyController = TextEditingController();
  final _doctorController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _scheduledDate;
  late TimeOfDay _scheduledTime;
  AppointmentVisitType _visitType = AppointmentVisitType.consulta;
  bool _reminder24h = true;
  bool _notifyTeam = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final defaultSchedule = _defaultSchedule();
    _scheduledDate = DateTime(
      defaultSchedule.year,
      defaultSchedule.month,
      defaultSchedule.day,
    );
    _scheduledTime = TimeOfDay(
      hour: defaultSchedule.hour,
      minute: defaultSchedule.minute,
    );
  }

  static DateTime _defaultSchedule() {
    final now = DateTime.now();
    var candidate = DateTime(now.year, now.month, now.day, 10, 0);
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  @override
  void dispose() {
    _specialtyController.dispose();
    _doctorController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime get _appointmentDateTime => DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('pt', 'BR'),
      helpText: 'Data da consulta',
    );
    if (picked != null) {
      setState(
        () => _scheduledDate =
            DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
      helpText: 'Horario da consulta',
    );
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_appointmentDateTime.isAfter(DateTime.now())) {
      _showSnack('Escolha uma data e horario no futuro.', isError: true);
      return;
    }

    setState(() => _loading = true);

    final specialty = _specialtyController.text.trim();
    final doctor = _doctorController.text.trim();
    final location = _locationController.text.trim();
    final notes = _notesController.text.trim();

    final error = await createAppointment(
      ref,
      patientId: widget.patientId,
      input: CreateAppointmentInput(
        specialty: specialty,
        appointmentDate: _appointmentDateTime,
        doctor: doctor.isEmpty ? null : doctor,
        location: location.isEmpty ? null : location,
        visitType: _visitType,
        notes: notes.isEmpty ? null : notes,
        reminder24h: _reminder24h,
        notifyTeam: _notifyTeam,
      ),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _showSnack(error, isError: true);
      return;
    }

    Navigator.of(context).pop(true);
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

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardDark : AppTheme.cardNormal;
    final borderColor = isDark ? AppTheme.cardBorderDark : AppTheme.cardBorder;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Agendar consulta',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Registre consultas e exames do paciente.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Tipo'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppointmentVisitType.values.map((type) {
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: _visitType == type,
                    onSelected:
                        _loading ? null : (_) => setState(() => _visitType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _buildField(
                context,
                label: 'Especialidade ou titulo',
                hint: 'Ex.: Cardiologia',
                controller: _specialtyController,
                icon: Icons.medical_services_outlined,
                cardColor: cardColor,
                borderColor: borderColor,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe a especialidade' : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                context,
                label: 'Medico(a) (opcional)',
                hint: 'Ex.: Dra. Helena Vasconcelos',
                controller: _doctorController,
                icon: Icons.person_outline,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 14),
              _buildField(
                context,
                label: 'Local (opcional)',
                hint: 'Ex.: Clinica CorVida — Sala 304',
                controller: _locationController,
                icon: Icons.location_on_outlined,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Data e horario'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _dateTile(
                      context,
                      label: _formatDate(_scheduledDate),
                      icon: Icons.calendar_today_outlined,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      onTap: _loading ? null : _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateTile(
                      context,
                      label: _formatTime(_scheduledTime),
                      icon: Icons.access_time,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      onTap: _loading ? null : _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildField(
                context,
                label: 'Anotacoes (opcional)',
                hint: 'Ex.: Levar exames recentes',
                controller: _notesController,
                icon: Icons.notes_outlined,
                cardColor: cardColor,
                borderColor: borderColor,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Lembrete 24h antes'),
                subtitle: const Text('Para voce, no app (em breve push)'),
                value: _reminder24h,
                onChanged:
                    _loading ? null : (v) => setState(() => _reminder24h = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Avisar a familia'),
                subtitle: const Text('Notificar o circulo de cuidado'),
                value: _notifyTeam,
                onChanged:
                    _loading ? null : (v) => setState(() => _notifyTeam = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Salvar consulta'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .labelMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _dateTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color cardColor,
    required Color borderColor,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: cardColor,
          prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
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
    );
  }

  Widget _buildField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required Color cardColor,
    required Color borderColor,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: borderColor),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: cardColor,
            prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
