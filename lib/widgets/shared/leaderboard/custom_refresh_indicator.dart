import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';

class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: DSColors.primary,
      backgroundColor: DSColors.surface,
      strokeWidth: 3,
      displacement: 60,
      child: child,
    );
  }
}
