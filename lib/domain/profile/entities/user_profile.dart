class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  String get firstName {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Cuidador';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
