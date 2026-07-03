class HydrationLog {
  const HydrationLog({
    required this.id,
    required this.patientId,
    required this.recordedAt,
    this.recordedBy,
    this.notes,
  });

  final String id;
  final String patientId;
  final DateTime recordedAt;
  final String? recordedBy;
  final String? notes;

  factory HydrationLog.fromJson(Map<String, dynamic> json) {
    return HydrationLog(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String).toLocal(),
      recordedBy: json['recorded_by'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
