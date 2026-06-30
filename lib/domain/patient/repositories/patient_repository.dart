import '../entities/patient.dart';

class CreatePatientInput {
  const CreatePatientInput({
    required this.fullName,
    required this.dateOfBirth,
    this.allergies,
    this.emergencyContact,
  });

  final String fullName;
  final DateTime dateOfBirth;
  final String? allergies;
  final String? emergencyContact;
}

abstract class PatientRepository {
  Future<Patient?> getActivePatient();

  Future<bool> hasActivePatient();

  /// Cria paciente e vinculo admin do cuidador (onboarding).
  Future<Patient> completeOnboarding(CreatePatientInput input);
}
