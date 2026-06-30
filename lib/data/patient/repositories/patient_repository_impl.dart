import '../../../domain/patient/entities/patient.dart';
import '../../../domain/patient/repositories/patient_repository.dart';
import '../../../domain/profile/repositories/profile_repository.dart';
import '../datasources/patient_remote_datasource.dart';

class PatientRepositoryImpl implements PatientRepository {
  PatientRepositoryImpl(this._remote, this._profileRepository);

  final PatientRemoteDataSource _remote;
  final ProfileRepository _profileRepository;

  @override
  Future<Patient?> getActivePatient() => _remote.getActivePatient();

  @override
  Future<bool> hasActivePatient() async {
    final patient = await getActivePatient();
    return patient != null;
  }

  @override
  Future<Patient> completeOnboarding(CreatePatientInput input) async {
    await _profileRepository.ensureCurrentProfile();

    final patient = await _remote.createPatient(
      fullName: input.fullName,
      dateOfBirth: input.dateOfBirth,
      allergies: input.allergies,
      emergencyContact: input.emergencyContact,
    );

    await _remote.createAdminMembership(patient.id);
    return patient;
  }
}
