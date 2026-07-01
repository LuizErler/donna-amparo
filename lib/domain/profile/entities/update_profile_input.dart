class UpdateProfileInput {
  const UpdateProfileInput({
    required this.fullName,
    this.phone,
  });

  final String fullName;
  final String? phone;
}
