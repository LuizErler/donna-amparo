import '../../../domain/hydration/entities/hydration_status.dart';
import '../../../domain/hydration/repositories/hydration_repository.dart';
import '../datasources/hydration_remote_datasource.dart';

class HydrationRepositoryImpl implements HydrationRepository {
  HydrationRepositoryImpl(this._remote);

  final HydrationRemoteDataSource _remote;

  @override
  Future<HydrationStatus> getStatus({required String patientId}) {
    return _remote.getStatus(patientId: patientId);
  }

  @override
  Future<void> recordHydration({required String patientId}) {
    return _remote.recordHydration(patientId: patientId);
  }
}
