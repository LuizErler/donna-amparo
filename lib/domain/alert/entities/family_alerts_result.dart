import 'family_alert.dart';

class FamilyAlertsResult {
  const FamilyAlertsResult({
    required this.attention,
    required this.resolved,
  });

  final List<FamilyAlert> attention;
  final List<FamilyAlert> resolved;

  static const empty = FamilyAlertsResult(attention: [], resolved: []);

  bool get isEmpty => attention.isEmpty && resolved.isEmpty;
}
