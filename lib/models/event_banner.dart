/// Event banner model for home screen announcements.
library;

enum EventBannerType { challenge, tournament, season, announcement }

class EventBanner {
  const EventBanner({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.actionRoute,
    this.gradientColors,
  });

  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final EventBannerType type;
  final String? actionRoute;
  final List<int>? gradientColors; // ARGB integers

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  int get hoursRemaining =>
      endDate.difference(DateTime.now()).inHours.clamp(0, 9999);

  String get timeRemainingLabel {
    final h = hoursRemaining;
    if (h >= 24) return '${h ~/ 24}d remaining';
    return '${h}h remaining';
  }
}
