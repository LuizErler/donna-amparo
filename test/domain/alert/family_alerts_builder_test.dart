import 'package:donna_amparo/domain/alert/services/family_alerts_builder.dart';
import 'package:donna_amparo/domain/appointment/entities/appointment.dart';
import 'package:donna_amparo/domain/appointment/entities/appointment_reminder_offset.dart';
import 'package:donna_amparo/domain/appointment/entities/appointments_list_result.dart';
import 'package:donna_amparo/domain/hydration/entities/hydration_log.dart';
import 'package:donna_amparo/domain/hydration/entities/hydration_status.dart';
import 'package:donna_amparo/domain/medication/entities/medication_day_period.dart';
import 'package:donna_amparo/domain/medication/entities/medication_dose.dart';
import 'package:donna_amparo/domain/medication/entities/medication_doses_result.dart';
import 'package:donna_amparo/domain/notification/entities/notification_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 6, 14, 0);

  MedicationDose dose({
    required String name,
    required String timeLabel,
    required DateTime scheduledFor,
    bool taken = false,
    bool isOverdue = false,
  }) {
    return MedicationDose(
      medicationId: 1,
      scheduleId: 1,
      name: name,
      instructions: '',
      timeLabel: timeLabel,
      scheduledTime: '$timeLabel:00',
      scheduledFor: scheduledFor,
      period: MedicationDayPeriod.afternoon,
      taken: taken,
      isOverdue: isOverdue,
    );
  }

  test('inclui dose pendente e hidratação em atenção', () {
    final pending = dose(
      name: 'Losartana',
      timeLabel: '08:00',
      scheduledFor: DateTime(2026, 7, 6),
    );

    final result = FamilyAlertsBuilder.build(
      patientFirstName: 'Maria',
      doses: MedicationDosesResult(overdue: [], today: [pending]),
      hydration: const HydrationStatus(),
      appointments: AppointmentsListResult.empty,
      now: now,
    );

    expect(result.attention, hasLength(2));
    expect(
      result.attention.any((a) => a.category == NotificationCategory.medications),
      isTrue,
    );
    expect(
      result.attention.any((a) => a.category == NotificationCategory.hydration),
      isTrue,
    );
  });

  test('inclui dose confirmada em resolvidos', () {
    final taken = dose(
      name: 'Metformina',
      timeLabel: '19:00',
      scheduledFor: DateTime(2026, 7, 6),
      taken: true,
    );

    final result = FamilyAlertsBuilder.build(
      patientFirstName: 'Maria',
      doses: MedicationDosesResult(overdue: [], today: [taken]),
      hydration: HydrationStatus(
        lastLog: HydrationLog(
          id: 'log-1',
          patientId: 'p1',
          recordedAt: now.subtract(const Duration(minutes: 30)),
        ),
      ),
      appointments: AppointmentsListResult.empty,
      now: now,
    );

    expect(result.attention, isEmpty);
    expect(result.resolved, hasLength(2));
  });

  test('consulta entra em atenção dentro da janela de lembrete', () {
    final appointment = Appointment(
      id: 10,
      specialty: 'Cardiologia',
      doctor: 'Dra. Helena',
      appointmentDate: now.add(const Duration(hours: 2)),
      personalReminders: const [AppointmentReminderOffset.hours2],
    );

    final result = FamilyAlertsBuilder.build(
      patientFirstName: 'Joaquim',
      doses: const MedicationDosesResult(overdue: [], today: []),
      hydration: HydrationStatus(
        lastLog: HydrationLog(
          id: 'log-2',
          patientId: 'p1',
          recordedAt: now.subtract(const Duration(minutes: 20)),
        ),
      ),
      appointments: AppointmentsListResult(upcoming: [appointment], past: []),
      now: now,
    );

    expect(result.attention, hasLength(1));
    expect(result.attention.first.category, NotificationCategory.appointments);
  });
}
