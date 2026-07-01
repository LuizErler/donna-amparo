import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/medication/entities/medication_frequency_preset.dart';
import '../../../domain/medication/entities/medication_schedule_mode.dart';
import '../../../domain/medication/entities/medication_summary.dart';
import '../../../domain/medication/entities/medication_treatment_period.dart';
import '../../../domain/medication/repositories/medication_repository.dart';
import '../../../domain/medication/services/medication_dose_generator.dart';
import 'providers/medication_providers.dart';

Future<bool?> showMedicationFormSheet(
  BuildContext context,
  WidgetRef ref, {
  required String patientId,
  MedicationSummary? existing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _MedicationFormSheet(
      patientId: patientId,
      existing: existing,
    ),
  );
}

@Deprecated('Use showMedicationFormSheet')
Future<bool?> showAddMedicationSheet(
  BuildContext context,
  WidgetRef ref, {
  required String patientId,
}) =>
    showMedicationFormSheet(context, ref, patientId: patientId);

class _MedicationFormSheet extends ConsumerStatefulWidget {
  const _MedicationFormSheet({
    required this.patientId,
    this.existing,
  });

  final String patientId;
  final MedicationSummary? existing;

  bool get isEditing => existing != null;

  @override
  ConsumerState<_MedicationFormSheet> createState() =>
      _MedicationFormSheetState();
}

class _MedicationFormSheetState extends ConsumerState<_MedicationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _durationController = TextEditingController(text: '7');
  final _intervalController = TextEditingController(text: '8');

  MedicationTreatmentType _treatmentType = MedicationTreatmentType.continuous;
  MedicationFrequencyPreset _frequency = MedicationFrequencyPreset.twiceDaily;
  DateTime _startDate = _today();
  TimeOfDay _anchorTime = const TimeOfDay(hour: 8, minute: 0);
  List<TimeOfDay> _times = List.of(
    MedicationFrequencyPreset.twiceDaily.defaultTimes,
  );
  bool _loading = false;

  late final String _initialName;
  late final String _initialDosage;
  late final String _initialInstructions;
  late final String _initialDuration;
  late final String _initialInterval;
  late final MedicationTreatmentType _initialTreatmentType;
  late final MedicationFrequencyPreset _initialFrequency;
  late final DateTime _initialStartDate;
  late final TimeOfDay _initialAnchorTime;
  late final List<TimeOfDay> _initialTimes;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    final med = widget.existing;
    if (med != null) {
      _nameController.text = med.name;
      _dosageController.text = med.dosage ?? '';
      _instructionsController.text = med.instructions ?? '';
      _startDate = med.startDate ?? _today();

      if (med.endDate != null && med.startDate != null) {
        _treatmentType = MedicationTreatmentType.limited;
        final days = med.endDate!.difference(med.startDate!).inDays + 1;
        _durationController.text = days.toString();
      }

      if (med.scheduleMode == MedicationScheduleMode.interval) {
        _frequency = MedicationFrequencyPreset.interval;
        _intervalController.text = (med.intervalHours ?? 8).toString();
        _anchorTime = _parseTime(med.anchorTime) ??
            const TimeOfDay(hour: 8, minute: 0);
      } else if (med.scheduleTimes.length == 1) {
        _frequency = MedicationFrequencyPreset.onceDaily;
        _times =
            med.scheduleTimes.map(_parseTime).whereType<TimeOfDay>().toList();
      } else if (med.scheduleTimes.length == 2) {
        _frequency = MedicationFrequencyPreset.twiceDaily;
        _times =
            med.scheduleTimes.map(_parseTime).whereType<TimeOfDay>().toList();
      } else if (med.scheduleTimes.length == 3) {
        _frequency = MedicationFrequencyPreset.threeTimesDaily;
        _times =
            med.scheduleTimes.map(_parseTime).whereType<TimeOfDay>().toList();
      } else {
        _frequency = MedicationFrequencyPreset.custom;
        _times =
            med.scheduleTimes.map(_parseTime).whereType<TimeOfDay>().toList();
        if (_times.isEmpty) _times = [const TimeOfDay(hour: 8, minute: 0)];
      }
    }

    _captureInitialSnapshot();
  }

  void _captureInitialSnapshot() {
    _initialName = _nameController.text;
    _initialDosage = _dosageController.text;
    _initialInstructions = _instructionsController.text;
    _initialDuration = _durationController.text;
    _initialInterval = _intervalController.text;
    _initialTreatmentType = _treatmentType;
    _initialFrequency = _frequency;
    _initialStartDate = _startDate;
    _initialAnchorTime = _anchorTime;
    _initialTimes = _times
        .map((t) => TimeOfDay(hour: t.hour, minute: t.minute))
        .toList();
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _sameTime(TimeOfDay a, TimeOfDay b) =>
      a.hour == b.hour && a.minute == b.minute;

  bool _sameTimes(List<TimeOfDay> a, List<TimeOfDay> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameTime(a[i], b[i])) return false;
    }
    return true;
  }

  bool get _isDirty =>
      _nameController.text != _initialName ||
      _dosageController.text != _initialDosage ||
      _instructionsController.text != _initialInstructions ||
      _durationController.text != _initialDuration ||
      _intervalController.text != _initialInterval ||
      _treatmentType != _initialTreatmentType ||
      _frequency != _initialFrequency ||
      !_sameDate(_startDate, _initialStartDate) ||
      !_sameTime(_anchorTime, _initialAnchorTime) ||
      !_sameTimes(_times, _initialTimes);

  Future<void> _requestClose() async {
    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar alteracoes?'),
        content: const Text(
          'As informacoes preenchidas serao perdidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    final h = int.tryParse(parts.first);
    final m = parts.length > 1 ? int.tryParse(parts[1]) : 0;
    if (h == null) return null;
    return TimeOfDay(hour: h, minute: m ?? 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _durationController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  bool get _isInterval => _frequency == MedicationFrequencyPreset.interval;

  void _applyPreset(MedicationFrequencyPreset preset) {
    setState(() {
      _frequency = preset;
      if (preset == MedicationFrequencyPreset.interval) return;
      if (preset != MedicationFrequencyPreset.custom) {
        _times = List.of(preset.defaultTimes);
      } else if (_times.isEmpty) {
        _times = [const TimeOfDay(hour: 8, minute: 0)];
      }
    });
  }

  MedicationScheduleMode get _scheduleMode => _isInterval
      ? MedicationScheduleMode.interval
      : MedicationScheduleMode.fixedTimes;

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('pt', 'BR'),
      helpText: 'Inicio do tratamento',
    );
    if (picked != null) {
      setState(
          () => _startDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickAnchorTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _anchorTime,
      helpText: 'Primeira dose',
    );
    if (picked != null) setState(() => _anchorTime = picked);
  }

  Future<void> _editTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
      helpText: 'Horario da dose',
      cancelText: 'Cancelar',
      confirmText: 'Salvar',
    );
    if (picked == null) return;

    final duplicate = _times.asMap().entries.any(
          (e) =>
              e.key != index &&
              e.value.hour == picked.hour &&
              e.value.minute == picked.minute,
        );
    if (duplicate) {
      _showSnack('Este horario ja foi adicionado.', isError: true);
      return;
    }

    setState(() {
      _times[index] = picked;
      _times.sort((a, b) {
        final aMin = a.hour * 60 + a.minute;
        final bMin = b.hour * 60 + b.minute;
        return aMin.compareTo(bMin);
      });
    });
  }

  Future<void> _addCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _times.isEmpty ? const TimeOfDay(hour: 8, minute: 0) : _times.last,
      helpText: 'Horario da dose',
    );
    if (picked == null) return;
    if (_times.any((t) => t.hour == picked.hour && t.minute == picked.minute)) {
      _showSnack('Este horario ja foi adicionado.', isError: true);
      return;
    }
    setState(() {
      _times.add(picked);
      _times.sort((a, b) =>
          (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    });
  }

  void _removeTime(int index) {
    if (_times.length <= 1) {
      _showSnack('Informe pelo menos um horario.', isError: true);
      return;
    }
    setState(() => _times.removeAt(index));
  }

  DateTime? _resolveEndDate() {
    if (_treatmentType == MedicationTreatmentType.continuous) return null;
    final days = int.tryParse(_durationController.text.trim());
    if (days == null || days < 1) return null;
    return MedicationTreatmentPeriod.endDateFromDuration(_startDate, days);
  }

  int? _resolveIntervalHours() {
    if (!_isInterval) return null;
    return int.tryParse(_intervalController.text.trim());
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  List<String> _previewLabels() {
    final endDate = _resolveEndDate();
    final intervalHours = _resolveIntervalHours();
    if (_isInterval && (intervalHours == null || intervalHours < 1)) {
      return [];
    }
    if (!_isInterval && _times.isEmpty) return [];

    return MedicationDoseGenerator.previewLabels(
      scheduleMode: _scheduleMode,
      startDate: _startDate,
      endDate: endDate,
      scheduleTimes: _times.map(_fmtTime).toList(),
      intervalHours: intervalHours,
      anchorTime: _isInterval ? _fmtTime(_anchorTime) : null,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isInterval) {
      final hours = _resolveIntervalHours();
      if (hours == null || hours < 1) {
        _showSnack('Informe o intervalo em horas.', isError: true);
        return;
      }
    } else if (_times.isEmpty) {
      _showSnack('Adicione pelo menos um horario.', isError: true);
      return;
    }

    final endDate = _resolveEndDate();
    if (_treatmentType == MedicationTreatmentType.limited && endDate == null) {
      _showSnack('Informe a duracao em dias (minimo 1).', isError: true);
      return;
    }

    setState(() => _loading = true);

    final name = _nameController.text.trim();
    final dosage = _dosageController.text.trim();
    final instructions = _instructionsController.text.trim();
    final intervalHours = _resolveIntervalHours();

    String? error;
    if (widget.isEditing) {
      error = await updateMedication(
        ref,
        patientId: widget.patientId,
        input: UpdateMedicationInput(
          medicationId: widget.existing!.id,
          name: name,
          dosage: dosage.isEmpty ? null : dosage,
          instructions: instructions.isEmpty ? null : instructions,
          scheduleTimes: List.unmodifiable(_times),
          startDate: _startDate,
          endDate: endDate,
          scheduleMode: _scheduleMode,
          intervalHours: intervalHours,
          anchorTime: _isInterval ? _anchorTime : null,
        ),
      );
    } else {
      error = await createMedication(
        ref,
        patientId: widget.patientId,
        input: CreateMedicationInput(
          name: name,
          dosage: dosage.isEmpty ? null : dosage,
          instructions: instructions.isEmpty ? null : instructions,
          scheduleTimes: List.unmodifiable(_times),
          startDate: _startDate,
          endDate: endDate,
          scheduleMode: _scheduleMode,
          intervalHours: intervalHours,
          anchorTime: _isInterval ? _anchorTime : null,
        ),
      );
    }

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

  String? _treatmentSummary() {
    if (_treatmentType == MedicationTreatmentType.continuous) {
      return 'A partir de ${_formatDate(_startDate)}, sem data de termino.';
    }
    final days = int.tryParse(_durationController.text.trim());
    if (days == null || days < 1) return null;
    final end = MedicationTreatmentPeriod.endDateFromDuration(_startDate, days);
    return '${_formatDate(_startDate)} ate ${_formatDate(end)} ($days dias).';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardDark : AppTheme.cardNormal;
    final borderColor = isDark ? AppTheme.cardBorderDark : AppTheme.cardBorder;
    final summary = _treatmentSummary();
    final preview = _previewLabels();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _requestClose();
      },
      child: Padding(
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
                _buildSheetHeader(
                  context,
                  cardColor: cardColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 20),
              _buildField(
                context,
                label: 'Nome do medicamento',
                hint: 'Ex.: Losartana',
                controller: _nameController,
                icon: Icons.medication_outlined,
                cardColor: cardColor,
                borderColor: borderColor,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                context,
                label: 'Dosagem (opcional)',
                hint: 'Ex.: 50mg',
                controller: _dosageController,
                icon: Icons.science_outlined,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 14),
              _buildField(
                context,
                label: 'Instrucoes (opcional)',
                hint: 'Ex.: Tomar apos o cafe',
                controller: _instructionsController,
                icon: Icons.notes_outlined,
                cardColor: cardColor,
                borderColor: borderColor,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Tipo de tratamento'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MedicationTreatmentType.values.map((type) {
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: _treatmentType == type,
                    onSelected: _loading
                        ? null
                        : (_) => setState(() => _treatmentType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'Inicio'),
              const SizedBox(height: 8),
              _buildDateTile(
                context,
                label: _formatDate(_startDate),
                cardColor: cardColor,
                borderColor: borderColor,
                icon: Icons.calendar_today_outlined,
                onTap: _loading ? null : _pickStartDate,
              ),
              if (_treatmentType == MedicationTreatmentType.limited) ...[
                const SizedBox(height: 14),
                _buildField(
                  context,
                  label: 'Duracao (dias corridos)',
                  hint: 'Ex.: 7',
                  controller: _durationController,
                  icon: Icons.event_outlined,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (_treatmentType != MedicationTreatmentType.limited) {
                      return null;
                    }
                    final days = int.tryParse(v?.trim() ?? '');
                    if (days == null || days < 1) {
                      return 'Informe pelo menos 1 dia';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ],
              if (summary != null) ...[
                const SizedBox(height: 8),
                Text(summary,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        )),
              ],
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Frequencia'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MedicationFrequencyPreset.values.map((preset) {
                  return ChoiceChip(
                    label: Text(preset.label),
                    selected: _frequency == preset,
                    onSelected:
                        _loading ? null : (_) => _applyPreset(preset),
                  );
                }).toList(),
              ),
              if (_isInterval) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        context,
                        label: 'Intervalo (horas)',
                        hint: 'Ex.: 8',
                        controller: _intervalController,
                        icon: Icons.timer_outlined,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (!_isInterval) return null;
                          final h = int.tryParse(v?.trim() ?? '');
                          if (h == null || h < 1) return 'Minimo 1 hora';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(context, 'Primeira dose'),
                          const SizedBox(height: 6),
                          _buildDateTile(
                            context,
                            label: _formatTime(_anchorTime),
                            cardColor: cardColor,
                            borderColor: borderColor,
                            icon: Icons.access_time,
                            onTap: _loading ? null : _pickAnchorTime,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 16),
                _buildSectionTitle(context, 'Horarios'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _times.length; i++)
                      InputChip(
                        label: Text(_formatTime(_times[i])),
                        onPressed: _loading ? null : () => _editTime(i),
                        deleteIcon:
                            _frequency == MedicationFrequencyPreset.custom
                                ? const Icon(Icons.close, size: 16)
                                : null,
                        onDeleted: _frequency ==
                                    MedicationFrequencyPreset.custom &&
                                !_loading
                            ? () => _removeTime(i)
                            : null,
                      ),
                  ],
                ),
                if (_frequency == MedicationFrequencyPreset.custom) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _addCustomTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: const Text('Adicionar horario'),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'Toque em um horario para ajustar.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildSectionTitle(context, 'Previsao de doses'),
                const SizedBox(height: 8),
                ...preview.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
              ],
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
                      : Text(widget.isEditing
                          ? 'Salvar alteracoes'
                          : 'Salvar medicamento'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _loading ? null : _requestClose,
                  child: const Text('Cancelar'),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHeader(
    BuildContext context, {
    required Color cardColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditing
                      ? 'Editar medicamento'
                      : 'Novo medicamento',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isEditing
                      ? 'Alteracoes valem para doses futuras. Confirmacoes anteriores sao mantidas.'
                      : 'Defina o remedio, a frequencia e o periodo de uso.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildCloseButton(cardColor: cardColor, borderColor: borderColor),
        ],
      ),
    );
  }

  Widget _buildCloseButton({
    required Color cardColor,
    required Color borderColor,
  }) {
    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: _loading ? null : _requestClose,
        borderRadius: BorderRadius.circular(14),
        child: Semantics(
          button: true,
          label: 'Fechar',
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.close,
              size: 22,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .labelMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildDateTile(
    BuildContext context, {
    required String label,
    required Color cardColor,
    required Color borderColor,
    required IconData icon,
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
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
          maxLines: maxLines,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
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
