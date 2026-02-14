import 'package:flutter/material.dart';
import 'package:multigame/screens/onboarding/welcome_splash_screen.dart';
import 'package:multigame/screens/onboarding/onboarding_tutorial_screen.dart';
import 'package:multigame/services/onboarding/onboarding_service.dart';

/// Wrapper that manages the complete onboarding flow
class OnboardingFlow extends StatefulWidget {
  final Widget child;
  final OnboardingService onboardingService;

  const OnboardingFlow({
    super.key,
    required this.child,
    required this.onboardingService,
  });

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  OnboardingStep _currentStep = OnboardingStep.checking;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final hasCompleted = await widget.onboardingService
        .hasCompletedOnboarding();
    setState(() {
      _currentStep = hasCompleted
          ? OnboardingStep.completed
          : OnboardingStep.splash;
    });
  }

  void _onSplashComplete() {
    setState(() {
      _currentStep = OnboardingStep.tutorial;
    });
  }

  Future<void> _onTutorialComplete() async {
    await widget.onboardingService.completeOnboarding();
    setState(() {
      _currentStep = OnboardingStep.completed;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case OnboardingStep.checking:
        // Show loading while checking status
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case OnboardingStep.splash:
        return WelcomeSplashScreen(onComplete: _onSplashComplete);

      case OnboardingStep.tutorial:
        return OnboardingTutorialScreen(onComplete: _onTutorialComplete);

      case OnboardingStep.completed:
        return widget.child;
    }
  }
}

/// Onboarding flow steps
enum OnboardingStep { checking, splash, tutorial, completed }
