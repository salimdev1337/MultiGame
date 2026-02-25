import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:multigame/config/service_locator.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/services/ads/ad_service.dart';

class AdBannerWidget extends StatelessWidget {
  static const double _bannerHeight = 50.0;

  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    }
    final adService = getIt<AdService>();
    if (!adService.isBannerLoaded || adService.bannerAd == null) {
      return const SizedBox(height: _bannerHeight);
    }
    return SafeArea(
      top: false,
      child: Container(
        alignment: Alignment.center,
        color: DSColors.backgroundSecondary,
        width: double.infinity,
        height: _bannerHeight,
        child: AdWidget(ad: adService.bannerAd!),
      ),
    );
  }
}
