import '../repositories/auth_repository.dart';

class UpdatePassword {
  const UpdatePassword(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String newPassword}) {
    return _repository.updatePassword(newPassword: newPassword);
  }
}
