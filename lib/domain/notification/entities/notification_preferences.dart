import 'notification_category.dart';

/// Preferências por categoria: alerta in-app e notificação push.
class CategoryPreference {
  const CategoryPreference({
    this.alertEnabled = true,
    this.pushEnabled = true,
  });

  final bool alertEnabled;
  final bool pushEnabled;

  CategoryPreference copyWith({
    bool? alertEnabled,
    bool? pushEnabled,
  }) {
    return CategoryPreference(
      alertEnabled: alertEnabled ?? this.alertEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'alertEnabled': alertEnabled,
        'pushEnabled': pushEnabled,
      };

  factory CategoryPreference.fromJson(Map<String, dynamic> json) {
    return CategoryPreference(
      alertEnabled: json['alertEnabled'] as bool? ?? true,
      pushEnabled: json['pushEnabled'] as bool? ?? true,
    );
  }
}

class NotificationPreferences {
  const NotificationPreferences({required this.categories});

  final Map<NotificationCategory, CategoryPreference> categories;

  factory NotificationPreferences.defaults() {
    return NotificationPreferences(
      categories: {
        for (final category in NotificationCategory.values)
          category: const CategoryPreference(),
      },
    );
  }

  bool isAlertEnabled(NotificationCategory category) =>
      categories[category]?.alertEnabled ?? true;

  bool isAlertEnabledForFilter(String filterLabel) {
    final category = NotificationCategory.fromFilterLabel(filterLabel);
    if (category == null) return true;
    return isAlertEnabled(category);
  }

  bool isPushEnabled(NotificationCategory category) =>
      categories[category]?.pushEnabled ?? true;

  NotificationPreferences updateCategory(
    NotificationCategory category,
    CategoryPreference preference,
  ) {
    return NotificationPreferences(
      categories: {...categories, category: preference},
    );
  }

  Map<String, dynamic> toJson() => {
        for (final entry in categories.entries)
          entry.key.name: entry.value.toJson(),
      };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final defaults = NotificationPreferences.defaults().categories;
    final parsed = Map<NotificationCategory, CategoryPreference>.from(defaults);

    for (final category in NotificationCategory.values) {
      final raw = json[category.name];
      if (raw is Map<String, dynamic>) {
        parsed[category] = CategoryPreference.fromJson(raw);
      }
    }

    return NotificationPreferences(categories: parsed);
  }
}
