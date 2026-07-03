import '../entities/hydration_status.dart';

abstract class HydrationRepository {
  Future<HydrationStatus> getStatus({required String patientId});

  Future<void> recordHydration({required String patientId});
}
