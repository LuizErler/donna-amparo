class Patient {
  const Patient({
    required this.id,
    required this.fullName,
    this.dateOfBirth,
    this.allergies,
    this.emergencyContact,
  });

  final String id;
  final String fullName;
  final DateTime? dateOfBirth;
  final String? allergies;
  final String? emergencyContact;

  String get firstName {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'quem você cuida';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    final dob = json['date_of_birth'] as String?;
    return Patient(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      dateOfBirth: dob != null ? DateTime.tryParse(dob) : null,
      allergies: json['allergies'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
    );
  }
}
