import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:multigame/utils/secure_logger.dart';

abstract class _AdIds {
  static const String banner = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  );
  static const String interstitial = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );
}

class AdService {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _bannerLoaded = false;
  bool _interstitialReady = false;

  bool get isBannerLoaded => _bannerLoaded;
  bool get isInterstitialReady => _interstitialReady;
  BannerAd? get bannerAd => _bannerAd;

  Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }
    try {
      await MobileAds.instance.initialize();
      SecureLogger.log('AdMob initialized', tag: 'Ads');
      await _loadBanner();
      await _loadInterstitial();
    } catch (e) {
      SecureLogger.error('Failed to initialize AdMob', error: e, tag: 'Ads');
    }
  }

  Future<void> _loadBanner() async {
    if (kIsWeb) {
      return;
    }
    _bannerAd = BannerAd(
      adUnitId: _AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _bannerLoaded = true;
          SecureLogger.log('Banner ad loaded', tag: 'Ads');
        },
        onAdFailedToLoad: (ad, error) {
          _bannerLoaded = false;
          ad.dispose();
          _bannerAd = null;
          SecureLogger.warn('Banner ad failed to load', tag: 'Ads');
        },
      ),
    );
    await _bannerAd!.load();
  }

  Future<void> _loadInterstitial() async {
    if (kIsWeb) {
      return;
    }
    await InterstitialAd.load(
      adUnitId: _AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialReady = true;
          SecureLogger.log('Interstitial ad loaded', tag: 'Ads');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _interstitialReady = false;
          SecureLogger.warn('Interstitial ad failed to load', tag: 'Ads');
        },
      ),
    );
  }

  Future<void> showInterstitialThen(VoidCallback onComplete) async {
    if (kIsWeb || !_interstitialReady || _interstitialAd == null) {
      onComplete();
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _interstitialReady = false;
        onComplete();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _interstitialReady = false;
        onComplete();
        _loadInterstitial();
      },
    );
    await _interstitialAd!.show();
  }

  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
