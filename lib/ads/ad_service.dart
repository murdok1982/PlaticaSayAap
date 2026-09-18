import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  bool _initialized = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  DateTime? _lastInterstitialShownAt;

  // Test Ad Unit IDs de Google AdMob (Oficiales para desarrollo y testing)
  // En producción se sobreescriben compilando con: --dart-define=ADMOB_ANDROID_BANNER=...
  static String get bannerAdUnitId {
    if (kReleaseMode) {
      const prodId = String.fromEnvironment('ADMOB_ANDROID_BANNER');
      if (prodId.isNotEmpty) return prodId;
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android Test Banner
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS Test Banner
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (kReleaseMode) {
      const prodId = String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL');
      if (prodId.isNotEmpty) return prodId;
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Android Test Interstitial
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // iOS Test Interstitial
    }
    return '';
  }

  static String get rewardedAdUnitId {
    if (kReleaseMode) {
      const prodId = String.fromEnvironment('ADMOB_ANDROID_REWARDED');
      if (prodId.isNotEmpty) return prodId;
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android Test Rewarded
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS Test Rewarded
    }
    return '';
  }

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      loadInterstitialAd();
      loadRewardedAd();
    } catch (e) {
      debugPrint('Error al inicializar MobileAds: $e');
    }
  }

  void loadInterstitialAd() {
    final adUnitId = interstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd(); // Precargar siguiente
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Fallo al cargar InterstitialAd: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Muestra el anuncio intersticial respetando un tiempo mínimo de descanso (cooldown)
  /// para no sobrecargar ni molestar al usuario al terminar una llamada o conversación.
  bool showInterstitialIfReady({Duration minInterval = const Duration(minutes: 2)}) {
    if (_interstitialAd == null) {
      loadInterstitialAd();
      return false;
    }

    final now = DateTime.now();
    if (_lastInterstitialShownAt != null &&
        now.difference(_lastInterstitialShownAt!) < minInterval) {
      return false; // Respetar el descanso entre anuncios
    }

    _lastInterstitialShownAt = now;
    _interstitialAd!.show();
    return true;
  }

  void loadRewardedAd() {
    final adUnitId = rewardedAdUnitId;
    if (adUnitId.isEmpty) return;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Fallo al cargar RewardedAd: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  void showRewardedAd({required VoidCallback onUserEarnedReward}) {
    if (_rewardedAd == null) {
      loadRewardedAd();
      return;
    }

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onUserEarnedReward();
      },
    );
  }
}

/// Widget reutilizable para mostrar un banner de AdMob en la parte inferior
class AppAdBanner extends StatefulWidget {
  final AdSize adSize;
  const AppAdBanner({super.key, this.adSize = AdSize.banner});

  @override
  State<AppAdBanner> createState() => _AppAdBannerState();
}

class _AppAdBannerState extends State<AppAdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    final unitId = AdService.bannerAdUnitId;
    if (unitId.isEmpty) return;

    _bannerAd = BannerAd(
      adUnitId: unitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd fallo al cargar: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
