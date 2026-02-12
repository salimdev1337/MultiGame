import 'package:shared_preferences/shared_preferences.dart';

/// Service to track onboarding completion and tutorial states
class OnboardingService {
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _hasSeenTutorialPrefix = 'has_seen_tutorial_';
  static const String _hasSeenCoachMarkPrefix = 'has_seen_coach_mark_';

  /// Check if user has completed initial onboarding
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, true);
  }

  /// Check if user has seen a specific tutorial
  Future<bool> hasSeenTutorial(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_hasSeenTutorialPrefix$tutorialId') ?? false;
  }

  /// Mark a tutorial as seen
  Future<void> markTutorialAsSeen(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_hasSeenTutorialPrefix$tutorialId', true);
  }

  /// Check if user has seen a specific coach mark
  Future<bool> hasSeenCoachMark(String coachMarkId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_hasSeenCoachMarkPrefix$coachMarkId') ?? false;
  }

  /// Mark a coach mark as seen
  Future<void> markCoachMarkAsSeen(String coachMarkId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_hasSeenCoachMarkPrefix$coachMarkId', true);
  }

  /// Reset all onboarding progress (useful for testing)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_hasCompletedOnboardingKey) ||
          key.startsWith(_hasSeenTutorialPrefix) ||
          key.startsWith(_hasSeenCoachMarkPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  /// Reset specific tutorial progress
  Future<void> resetTutorial(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_hasSeenTutorialPrefix$tutorialId');
  }

  /// Reset specific coach mark
  Future<void> resetCoachMark(String coachMarkId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_hasSeenCoachMarkPrefix$coachMarkId');
  }
}
