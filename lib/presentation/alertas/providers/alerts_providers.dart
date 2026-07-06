import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/alert/entities/family_alerts_result.dart';
import '../../../domain/alert/services/family_alerts_builder.dart';
import '../../appointment/providers/appointment_providers.dart';
import '../../care/providers/care_providers.dart';
import '../../hydration/providers/hydration_providers.dart';
import '../../medication/providers/medication_providers.dart';

/// Alertas in-app derivados de medicamentos, hidratação e consultas.
final familyAlertsProvider = FutureProvider<FamilyAlertsResult>((ref) async {
  ref.watch(authStateVersionProvider);

  final patient = await ref.watch(activePatientProvider.future);
  if (patient == null) return FamilyAlertsResult.empty;

  final doses = await ref.watch(medicationDosesProvider.future);
  final hydration = await ref.watch(hydrationStatusProvider.future);
  final appointments = await ref.watch(patientAppointmentsProvider.future);

  return FamilyAlertsBuilder.build(
    patientFirstName: patient.firstName,
    doses: doses,
    hydration: hydration,
    appointments: appointments,
  );
});
