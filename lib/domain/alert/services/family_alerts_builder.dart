import 'package:flutter/material.dart';

import '../../appointment/entities/appointment.dart';
import '../../appointment/entities/appointment_reminder_offset.dart';
import '../../appointment/entities/appointments_list_result.dart';
import '../../hydration/entities/hydration_status.dart';
import '../../medication/entities/medication_dose.dart';
import '../../medication/entities/medication_doses_result.dart';
import '../../notification/entities/notification_category.dart';
import '../entities/family_alert.dart';
import '../entities/family_alerts_result.dart';

/// Monta alertas in-app a partir das mesmas regras da Home (pendências).
class FamilyAlertsBuilder {
  const FamilyAlertsBuilder._();

  static FamilyAlertsResult build({
    required String patientFirstName,
    required MedicationDosesResult doses,
    required HydrationStatus hydration,
    required AppointmentsListResult appointments,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final attention = <FamilyAlert>[];
    final resolved = <FamilyAlert>[];

    _addMedicationAlerts(
      attention: attention,
      resolved: resolved,
      doses: doses,
      patientFirstName: patientFirstName,
      now: reference,
    );

    _addHydrationAlerts(
      attention: attention,
      resolved: resolved,
      hydration: hydration,
      patientFirstName: patientFirstName,
      now: reference,
    );

    _addAppointmentAlerts(
      attention: attention,
      resolved: resolved,
      appointments: appointments,
      patientFirstName: patientFirstName,
      now: reference,
    );

    attention.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    resolved.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return FamilyAlertsResult(attention: attention, resolved: resolved);
  }

  static void _addMedicationAlerts({
    required List<FamilyAlert> attention,
    required List<FamilyAlert> resolved,
    required MedicationDosesResult doses,
    required String patientFirstName,
    required DateTime now,
  }) {
    for (final dose in doses.attentionPendingDoses) {
      attention.add(
        FamilyAlert(
          id: _medicationAttentionId(dose),
          title: dose.isPastDayOverdue || dose.isLateToday
              ? '${dose.displayName} ainda não confirmada'
              : 'Medicamento das ${dose.timeLabel}',
          description: _medicationAttentionDescription(dose, patientFirstName),
          timeLabel: _formatTimeLabel(dose.scheduledAt, now),
          occurredAt: dose.scheduledAt,
          category: NotificationCategory.medications,
          resolved: false,
          icon: Icons.medication_outlined,
        ),
      );
    }

    for (final dose in doses.today.where((d) => d.taken)) {
      resolved.add(
        FamilyAlert(
          id: _medicationResolvedId(dose),
          title: '${dose.displayName} das ${dose.timeLabel} confirmada',
          description:
              'Dose de ${dose.displayName} registrada para $patientFirstName.',
          timeLabel: _formatTimeLabel(dose.scheduledAt, now),
          occurredAt: dose.scheduledAt,
          category: NotificationCategory.medications,
          resolved: true,
          icon: Icons.check_circle_outline,
        ),
      );
    }
  }

  static void _addHydrationAlerts({
    required List<FamilyAlert> attention,
    required List<FamilyAlert> resolved,
    required HydrationStatus hydration,
    required String patientFirstName,
    required DateTime now,
  }) {
    if (hydration.needsAttention) {
      attention.add(
        FamilyAlert(
          id: 'hydration-attention',
          title: 'Lembrete de hidratação',
          description: hydration.messageForPatient(patientFirstName),
          timeLabel: hydration.lastLog == null
              ? 'Sem registros'
              : _formatTimeLabel(hydration.lastLog!.recordedAt, now),
          occurredAt: hydration.lastLog?.recordedAt ?? now,
          category: NotificationCategory.hydration,
          resolved: false,
          icon: Icons.water_drop_outlined,
        ),
      );
      return;
    }

    final lastLog = hydration.lastLog;
    if (lastLog != null && _isToday(lastLog.recordedAt, now)) {
      resolved.add(
        FamilyAlert(
          id: 'hydration-resolved-${lastLog.id}',
          title: 'Hidratação registrada',
          description:
              'Última ingestão de água de $patientFirstName ${hydration.elapsedLabel.toLowerCase()}.',
          timeLabel: _formatTimeLabel(lastLog.recordedAt, now),
          occurredAt: lastLog.recordedAt,
          category: NotificationCategory.hydration,
          resolved: true,
          icon: Icons.check_circle_outline,
        ),
      );
    }
  }

  static void _addAppointmentAlerts({
    required List<FamilyAlert> attention,
    required List<FamilyAlert> resolved,
    required AppointmentsListResult appointments,
    required String patientFirstName,
    required DateTime now,
  }) {
    for (final appointment in appointments.upcoming) {
      if (!_isWithinReminderWindow(appointment, now)) continue;

      final date = appointment.appointmentDate!.toLocal();
      attention.add(
        FamilyAlert(
          id: 'appointment-attention-${appointment.id}',
          title: '${appointment.displaySpecialty} se aproxima',
          description: _appointmentAttentionDescription(
            appointment,
            patientFirstName,
          ),
          timeLabel: _formatTimeLabel(date, now),
          occurredAt: date,
          category: NotificationCategory.appointments,
          resolved: false,
          icon: Icons.calendar_today_outlined,
        ),
      );
    }

    for (final appointment in appointments.past) {
      final date = appointment.appointmentDate?.toLocal();
      if (date == null) continue;
      if (now.difference(date) > const Duration(days: 7)) continue;

      resolved.add(
        FamilyAlert(
          id: 'appointment-resolved-${appointment.id}',
          title: '${appointment.displaySpecialty} realizada',
          description: _appointmentResolvedDescription(
            appointment,
            patientFirstName,
          ),
          timeLabel: _formatTimeLabel(date, now),
          occurredAt: date,
          category: NotificationCategory.appointments,
          resolved: true,
          icon: Icons.check_circle_outline,
        ),
      );
    }
  }

  static bool _isWithinReminderWindow(Appointment appointment, DateTime now) {
    final date = appointment.appointmentDate?.toLocal();
    if (date == null || !date.isAfter(now)) return false;

    final offsets = <AppointmentReminderOffset>{
      ...appointment.personalReminders,
      ...appointment.teamNotifyReminders,
    };

    if (offsets.isEmpty) {
      return date.difference(now) <= const Duration(hours: 24);
    }

    for (final offset in offsets) {
      final fireAt = date.subtract(Duration(minutes: offset.minutesBefore));
      if (!now.isBefore(fireAt) && now.isBefore(date)) return true;
    }
    return false;
  }

  static String _medicationAttentionDescription(
    MedicationDose dose,
    String patientFirstName,
  ) {
    if (dose.isPastDayOverdue && dose.overdueLabel.isNotEmpty) {
      return '$patientFirstName ainda não tomou ${dose.displayName} · ${dose.overdueLabel}. Alguém pode verificar?';
    }
    return '$patientFirstName ainda não tomou ${dose.displayName} (${dose.timeLabel}). Alguém pode verificar?';
  }

  static String _appointmentAttentionDescription(
    Appointment appointment,
    String patientFirstName,
  ) {
    final doctor = appointment.displayDoctor;
    final when = appointment.scheduleLabel;
    if (doctor.isNotEmpty) {
      return 'Consulta de $patientFirstName com $doctor · $when.';
    }
    return 'Consulta de $patientFirstName · $when.';
  }

  static String _appointmentResolvedDescription(
    Appointment appointment,
    String patientFirstName,
  ) {
    final when = appointment.historyLabel;
    return 'Consulta de $patientFirstName em $when.';
  }

  static String _medicationAttentionId(MedicationDose dose) {
    return 'med-attention-${dose.medicationId}-${dose.scheduleId}-${dose.scheduledFor.millisecondsSinceEpoch}-${dose.scheduledTime}';
  }

  static String _medicationResolvedId(MedicationDose dose) {
    return 'med-resolved-${dose.medicationId}-${dose.scheduleId}-${dose.scheduledFor.millisecondsSinceEpoch}-${dose.scheduledTime}';
  }

  static bool _isToday(DateTime value, DateTime now) {
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  static String _formatTimeLabel(DateTime dateTime, DateTime now) {
    final local = dateTime.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(local.year, local.month, local.day);
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final clock = '$h:$m';

    if (date == today) return 'Hoje, $clock';
    if (date == today.subtract(const Duration(days: 1))) return 'Ontem, $clock';

    final diff = today.difference(date).inDays;
    if (diff > 1 && diff < 7) return 'Há $diff dias';

    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} · $clock';
  }
}
