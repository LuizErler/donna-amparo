import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../domain/profile/entities/update_profile_input.dart';
import '../../../domain/profile/repositories/profile_repository.dart';
import '../../care/providers/care_providers.dart';

final profileEditControllerProvider =
    StateNotifierProvider<ProfileEditController, AsyncValue<void>>((ref) {
  return ProfileEditController(
    profileRepository: ref.watch(profileRepositoryProvider),
    ref: ref,
  );
});

class ProfileEditController extends StateNotifier<AsyncValue<void>> {
  ProfileEditController({
    required ProfileRepository profileRepository,
    required Ref ref,
  })  : _profileRepository = profileRepository,
        _ref = ref,
        super(const AsyncValue.data(null));

  final ProfileRepository _profileRepository;
  final Ref _ref;

  bool get isLoading => state.isLoading;

  Future<String?> save(UpdateProfileInput input) async {
    state = const AsyncValue.loading();
    try {
      await _profileRepository.updateCurrentProfile(input);
      invalidateCareContext(_ref);
      state = const AsyncValue.data(null);
      return null;
    } on AppException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return e.message;
    } catch (e) {
      const message = 'Erro ao salvar perfil. Tente novamente.';
      state = AsyncValue.error(message, StackTrace.current);
      return message;
    }
  }
}
