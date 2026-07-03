import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/appointment/entities/appointment.dart';
import '../../../domain/calendar/entities/calendar_event.dart';
import '../../../domain/medication/entities/medication_dose.dart';
import '../../appointment/add_appointment_sheet.dart';
import '../../appointment/appointment_detail_sheet.dart';
import '../../appointment/providers/appointment_providers.dart';
import '../../calendar/calendar_event_mapper.dart';
import '../../calendar/providers/calendar_providers.dart';
import '../../care/providers/care_providers.dart';
import '../../care/providers/care_team_providers.dart';
import '../../shared/app_snackbar.dart';
import '../../shell/shell_page_header.dart';
import 'mock_calendar_events.dart';

class CalendarioPage extends ConsumerStatefulWidget {
  const CalendarioPage({super.key});

  @override
  ConsumerState<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends ConsumerState<CalendarioPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = _focusedDay;
  }

  List<CalendarEvent> _eventsForDay(
    DateTime day,
    List<MedicationDose> medicationDoses,
    List<Appointment> appointments,
  ) {
    final manualEvents = MockCalendarEvents.forDay(day)
        .where((e) => e.type == CalendarEventType.manual)
        .toList();
    final appointmentEvents = CalendarEventMapper.appointmentsOnDay(
      appointments,
      day,
    ).map(CalendarEventMapper.fromAppointment);
    final medEvents = CalendarEventMapper.dosesOnDay(medicationDoses, day)
        .map(CalendarEventMapper.fromMedicationDose);
    return [...manualEvents, ...appointmentEvents, ...medEvents]
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  List<CalendarEventType> _typesOnDay(
    DateTime day,
    List<MedicationDose> medicationDoses,
    List<Appointment> appointments,
  ) {
    final types = MockCalendarEvents.typesOnDay(day)
        .where((t) => t == CalendarEventType.manual)
        .toSet();
    if (CalendarEventMapper.appointmentsOnDay(appointments, day).isNotEmpty) {
      types.add(CalendarEventType.appointment);
    }
    if (CalendarEventMapper.dosesOnDay(medicationDoses, day).isNotEmpty) {
      types.add(CalendarEventType.medicationDose);
    }
    return types.toList();
  }

  @override
  Widget build(BuildContext context) {
    final monthKey = calendarMonthKey(_focusedDay);
    final dosesAsync = ref.watch(medicationCalendarDosesProvider(monthKey));
    final appointmentsAsync =
        ref.watch(appointmentCalendarAppointmentsProvider(monthKey));
    final medicationDoses = dosesAsync.valueOrNull ?? const <MedicationDose>[];
    final appointments = appointmentsAsync.valueOrNull ?? const <Appointment>[];
    final eventsForSelectedDay =
        _eventsForDay(_selectedDay, medicationDoses, appointments);
    final isLoading =
        (dosesAsync.isLoading && medicationDoses.isEmpty) ||
        (appointmentsAsync.isLoading && appointments.isEmpty);
    final roleAsync = ref.watch(currentCareRoleProvider);
    final canManage = roleAsync.maybeWhen(
      data: (role) => role?.canCreateMedsAndAppointments ?? false,
      orElse: () => false,
    );

    final cardColor = AppTheme.cardSurface(context);
    final borderColor = AppTheme.cardOutline(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: const ShellPageHeader(
                title: 'Calendário',
                subtitle: 'Consultas, medicamentos e compromissos.',
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildCalendar(
                context,
                cardColor,
                borderColor,
                medicationDoses,
                appointments,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildLegend(context),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _dayTitle(_selectedDay),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _refreshCalendar(ref),
                child: isLoading
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: const [
                          SizedBox(height: 120),
                          Center(child: CircularProgressIndicator()),
                        ],
                      )
                    : eventsForSelectedDay.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            children: [
                              const SizedBox(height: 120),
                              Center(
                                child: Text(
                                  'Nenhum evento neste dia.',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: eventsForSelectedDay.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final event = eventsForSelectedDay[index];
                              return _EventTile(
                                event: event,
                                cardColor: cardColor,
                                borderColor: borderColor,
                                onTap: () => _onEventTap(
                                  context,
                                  event,
                                  appointments,
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => _onScheduleAppointment(context),
              tooltip: 'Agendar consulta',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    Color cardColor,
    Color borderColor,
    List<MedicationDose> medicationDoses,
    List<Appointment> appointments,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: TableCalendar<CalendarEventType>(
        firstDay: DateTime(2026, 1, 1),
        lastDay: DateTime(2027, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        locale: 'pt_BR',
        eventLoader: (day) => _typesOnDay(day, medicationDoses, appointments),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          markerSize: 6,
          outsideDaysVisible: false,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: events.take(3).map((type) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: _colorForType(type),
                    shape: BoxShape.circle,
                  ),
                );
              }).toList(),
            );
          },
        ),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        onPageChanged: (focused) {
          _focusedDay = focused;
        },
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendDot(
          color: _colorForType(CalendarEventType.appointment),
          label: 'Consultas',
        ),
        _LegendDot(
          color: _colorForType(CalendarEventType.medicationDose),
          label: 'Medicamentos',
        ),
        _LegendDot(
          color: _colorForType(CalendarEventType.manual),
          label: 'Outros',
        ),
      ],
    );
  }

  Future<void> _onEventTap(
    BuildContext context,
    CalendarEvent event,
    List<Appointment> appointments,
  ) async {
    if (event.type == CalendarEventType.appointment) {
      final id = int.tryParse(event.sourceId ?? '');
      Appointment? appointment;
      if (id != null) {
        for (final a in appointments) {
          if (a.id == id) {
            appointment = a;
            break;
          }
        }
      }
      if (appointment == null) {
        showAppSnack(
          context,
          'Consulta não encontrada.',
          variant: AppSnackVariant.error,
        );
        return;
      }

      final role = await ref.read(currentCareRoleProvider.future);
      final canManage = role?.canCreateMedsAndAppointments ?? false;
      final patient = await ref.read(activePatientProvider.future);
      if (!context.mounted) return;
      if (patient == null) {
        showAppSnack(
          context,
          'Paciente não encontrado.',
          variant: AppSnackVariant.error,
        );
        return;
      }

      final changed = await showAppointmentDetailSheet(
        context,
        ref,
        patientId: patient.id,
        appointment: appointment,
        canManage: canManage,
      );
      if (!context.mounted || changed != true) return;
      showAppSuccessSnack(context, 'Consulta atualizada.');
      ref.invalidate(appointmentCalendarAppointmentsProvider);
      ref.invalidate(patientAppointmentsProvider);
      return;
    }

    final label = switch (event.type) {
      CalendarEventType.medicationDose => 'Gerencie doses na aba Medicamentos.',
      CalendarEventType.manual =>
        'Compromissos manuais estarão disponíveis em versão futura.',
      CalendarEventType.appointment => '',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _onScheduleAppointment(BuildContext context) async {
    final patient = await ref.read(activePatientProvider.future);
    if (!context.mounted) return;
    if (patient == null) {
      showAppSnack(
        context,
        'Paciente não encontrado.',
        variant: AppSnackVariant.error,
      );
      return;
    }

    final saved = await showAddAppointmentSheet(
      context,
      ref,
      patientId: patient.id,
      initialSchedule: _selectedDay,
    );
    if (!context.mounted || saved != true) return;

    ref.invalidate(appointmentCalendarAppointmentsProvider);
    ref.invalidate(patientAppointmentsProvider);
    showAppSuccessSnack(context, 'Consulta agendada com sucesso.');
  }

  Future<void> _refreshCalendar(WidgetRef ref) async {
    final monthKey = calendarMonthKey(_focusedDay);
    ref.invalidate(medicationCalendarDosesProvider(monthKey));
    ref.invalidate(appointmentCalendarAppointmentsProvider(monthKey));
    await ref.read(medicationCalendarDosesProvider(monthKey).future);
    await ref.read(appointmentCalendarAppointmentsProvider(monthKey).future);
  }

  static Color _colorForType(CalendarEventType type) {
    return switch (type) {
      CalendarEventType.appointment => const Color(0xFF5C8A6E),
      CalendarEventType.medicationDose => AppTheme.primary,
      CalendarEventType.manual => const Color(0xFF6B7A8D),
    };
  }

  static String _dayTitle(DateTime day) {
    const weekdays = [
      'Segunda',
      'Terca',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sabado',
      'Domingo',
    ];
    const months = [
      'janeiro',
      'fevereiro',
      'marco',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    final weekday = weekdays[(day.weekday - 1) % 7];
    return '$weekday, ${day.day} de ${months[day.month - 1]}';
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.cardColor,
    required this.borderColor,
    required this.onTap,
  });

  final CalendarEvent event;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = _CalendarioPageState._colorForType(event.type);
    final time =
        '${event.start.hour.toString().padLeft(2, '0')}:${event.start.minute.toString().padLeft(2, '0')}';

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  time,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(event.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(
                _iconForType(event.type),
                color: typeColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForType(CalendarEventType type) {
    return switch (type) {
      CalendarEventType.appointment => Icons.calendar_today_outlined,
      CalendarEventType.medicationDose => Icons.medication_outlined,
      CalendarEventType.manual => Icons.event_outlined,
    };
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
