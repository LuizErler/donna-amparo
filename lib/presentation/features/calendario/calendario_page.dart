import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/calendar/entities/calendar_event.dart';
import '../../shell/shell_page_header.dart';
import '../consultas/consultas_page.dart';
import 'mock_calendar_events.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime(2026, 6, 27);
    _selectedDay = _focusedDay;
  }

  List<CalendarEvent> get _eventsForSelectedDay =>
      MockCalendarEvents.forDay(_selectedDay);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardDark : AppTheme.cardNormal;
    final borderColor =
        isDark ? AppTheme.cardBorderDark : AppTheme.cardBorder;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: const ShellPageHeader(
                title: 'Calendario',
                subtitle: 'Consultas, medicamentos e compromissos.',
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildCalendar(context, cardColor, borderColor),
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
              child: _eventsForSelectedDay.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum evento neste dia.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: _eventsForSelectedDay.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final event = _eventsForSelectedDay[index];
                        return _EventTile(
                          event: event,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          onTap: () => _onEventTap(context, event),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddPressed(context),
        tooltip: 'Novo compromisso',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    Color cardColor,
    Color borderColor,
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
        eventLoader: (day) => MockCalendarEvents.typesOnDay(day).toList(),
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

  void _onEventTap(BuildContext context, CalendarEvent event) {
    if (event.type == CalendarEventType.appointment) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ConsultasPage()),
      );
      return;
    }

    final label = switch (event.type) {
      CalendarEventType.medicationDose => 'Gerencie doses na aba Medicamentos.',
      CalendarEventType.manual => 'Detalhes de compromissos em breve.',
      CalendarEventType.appointment => '',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label), behavior: SnackBarBehavior.floating),
    );
  }

  void _onAddPressed(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Novo compromisso',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Agendar consulta'),
                subtitle: const Text('Use a aba Consultas (em breve: fluxo dedicado)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConsultasPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('Outro compromisso'),
                subtitle: const Text('Disponivel na integracao com Supabase'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Compromissos manuais — em breve.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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
