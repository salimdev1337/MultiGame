import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import 'package:multigame/config/service_locator.dart';
import 'package:multigame/services/ads/ad_service.dart';

abstract class NavigationUtils {
  static void goHome(BuildContext context) {
    getIt<AdService>().showInterstitialThen(() {
      if (context.mounted) {
        context.go(AppRoutes.home);
      }
    });
  }
}
