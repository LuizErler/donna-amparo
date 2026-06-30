import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../domain/patient/repositories/patient_repository.dart';
import '../../care/providers/care_providers.dart';

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, AsyncValue<void>>((ref) {
  return OnboardingController(
    patientRepository: ref.watch(patientRepositoryProvider),
    ref: ref,
  );
});

class OnboardingController extends StateNotifier<AsyncValue<void>> {
  OnboardingController({
    required PatientRepository patientRepository,
    required Ref ref,
  })  : _patientRepository = patientRepository,
        _ref = ref,
        super(const AsyncValue.data(null));

  final PatientRepository _patientRepository;
  final Ref _ref;

  bool get isLoading => state.isLoading;

  Future<String?> submit(CreatePatientInput input) async {
    state = const AsyncValue.loading();
    try {
      await _patientRepository.completeOnboarding(input);
      invalidateCareContext(_ref);
      state = const AsyncValue.data(null);
      return null;
    } on AppException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return e.message;
    } catch (e) {
      final message = e.toString();
      state = AsyncValue.error(message, StackTrace.current);
      return message;
    }
  }
}
