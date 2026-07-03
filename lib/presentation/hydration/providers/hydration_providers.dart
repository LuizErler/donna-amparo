import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/guarded_action.dart';
import '../../../data/hydration/datasources/hydration_remote_datasource.dart';
import '../../../data/hydration/repositories/hydration_repository_impl.dart';
import '../../../domain/hydration/entities/hydration_status.dart';
import '../../../domain/hydration/repositories/hydration_repository.dart';
import '../../care/providers/care_providers.dart';

final hydrationRemoteDataSourceProvider =
    Provider<HydrationRemoteDataSource>((ref) {
  return HydrationRemoteDataSource();
});

final hydrationRepositoryProvider = Provider<HydrationRepository>((ref) {
  return HydrationRepositoryImpl(ref.watch(hydrationRemoteDataSourceProvider));
});

final hydrationStatusProvider = FutureProvider<HydrationStatus>((ref) async {
  ref.watch(authStateVersionProvider);

  final patient = await ref.watch(activePatientProvider.future);
  if (patient == null) return const HydrationStatus();

  return ref.watch(hydrationRepositoryProvider).getStatus(
        patientId: patient.id,
      );
});

Future<String?> recordHydration(WidgetRef ref) async {
  final patient = await ref.read(activePatientProvider.future);
  if (patient == null) return 'Paciente não encontrado.';

  return runGuarded(
    () async {
      await ref.read(hydrationRepositoryProvider).recordHydration(
            patientId: patient.id,
          );
      ref.invalidate(hydrationStatusProvider);
    },
    fallback: 'Erro ao registrar hidratação.',
  );
}
