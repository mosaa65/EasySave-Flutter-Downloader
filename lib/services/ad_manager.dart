import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/AdSettingsPage.dart';

class AdManager {
  // Singleton Implementation
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  // Configuration Constants
  static const String privacyPolicyUrl = 'https://your-real-domain.com/privacy';
  static const int _maxInterstitialInterval = 5; // Minutes
  static const int _maxBannerRetries = 3;

  // Ad Unit IDs (Test Mode)
  static const String _topBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _bottomBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _interstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _rewardedId = 'ca-app-pub-3940256099942544/5224354917';

  // Ad Instances and State Management
  BannerAd? _topBannerAd;
  BannerAd? _bottomBannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _adsEnabled = true;
  bool _bannerAdsEnabled = true;
  bool _interstitialAdsEnabled = true;
  bool _rewardedAdsEnabled = true;
  DateTime? _lastInterstitialTime;
  int _bannerRetryCount = 0;

  // Getters
  bool get adsEnabled => _adsEnabled;

  Future<void> initialize() async {
    try {
      if (!await _checkInternetConnection()) {
        print('⚠️ Ads initialization skipped - No internet connection');
        return;
      }

      await MobileAds.instance.initialize();
      final prefs = await SharedPreferences.getInstance();
      await _loadUserPreferences(prefs);

      if (_adsEnabled) {
        _loadAllAds();
        print('✅ Ads system initialized successfully');
      }
    } catch (e) {
      print('❌ Ads initialization failed: $e');
    }
  }

  Future<void> reloadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadUserPreferences(prefs);
    _disposeExistingAds();
    _loadAllAds();
    print('⚙️ تم تحديث إعدادات الإعلانات');
  }

  void _disposeExistingAds() {
    _topBannerAd?.dispose();
    _bottomBannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }

  void dispose() {
    _disposeExistingAds();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _loadUserPreferences(SharedPreferences prefs) async {
    try {
      _adsEnabled = prefs.getBool('adsEnabled') ?? true;
      _bannerAdsEnabled = prefs.getBool('bannerAdsEnabled') ?? true;
      _interstitialAdsEnabled = prefs.getBool('interstitialAdsEnabled') ?? true;
      _rewardedAdsEnabled = prefs.getBool('rewardedAdsEnabled') ?? true;

      final lastTime = prefs.getString('lastInterstitialTime');
      _lastInterstitialTime = lastTime != null ? DateTime.parse(lastTime) : null;
    } catch (e) {
      print('⚠️ Error loading preferences: $e - Using default settings');
      _resetToDefaultSettings();
    }
  }

  void _resetToDefaultSettings() {
    _adsEnabled = true;
    _bannerAdsEnabled = true;
    _interstitialAdsEnabled = true;
    _rewardedAdsEnabled = true;
    _lastInterstitialTime = null;
    print('⚙️ Restored default ad settings');
  }

  void _loadAllAds() {
    if (_bannerAdsEnabled) {
      _loadBannerAd(_topBannerId, (ad) => _topBannerAd = ad);
      _loadBannerAd(_bottomBannerId, (ad) => _bottomBannerAd = ad);
    }
    if (_interstitialAdsEnabled) _loadInterstitialAd();
    if (_rewardedAdsEnabled) _loadRewardedAd();
  }

  void _loadBannerAd(String adId, Function(BannerAd) onLoaded) {
    if (!_adsEnabled || _bannerRetryCount >= _maxBannerRetries) {
      print('🚫 Banner ads disabled or max retries reached');
      return;
    }

    print('🔄 Loading banner: $adId (Attempt ${_bannerRetryCount + 1}/$_maxBannerRetries)');
    BannerAd(
      adUnitId: adId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ Banner loaded: ${ad.adUnitId}');
          onLoaded(ad as BannerAd);
          _bannerRetryCount = 0;
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Banner failed: ${error.message}');
          ad.dispose();
          if (_bannerRetryCount < _maxBannerRetries) {
            _bannerRetryCount++;
            Future.delayed(
              const Duration(seconds: 30),
                  () => _loadBannerAd(adId, onLoaded),
            );
          }
        },
      ),
    ).load();
  }

  bool get canShowInterstitial {
    if (!_interstitialAdsEnabled) return false;
    final lastShown = _lastInterstitialTime;
    return lastShown == null ||
        DateTime.now().difference(lastShown).inMinutes >= _maxInterstitialInterval;
  }

  void _updateInterstitialTime() async {
    try {
      _lastInterstitialTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'lastInterstitialTime',
        _lastInterstitialTime!.toIso8601String(),
      );
    } catch (e) {
      print('⚠️ Error saving interstitial time: $e');
    }
  }

  void _loadInterstitialAd() {
    print('🔄 Loading interstitial ad...');
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ Interstitial loaded');
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('❌ Interstitial failed: ${error.message}');
          Future.delayed(const Duration(minutes: 5), _loadInterstitialAd);
        },
      ),
    );
  }

  void showInterstitialAd(VoidCallback onCompleted) {
    if (_interstitialAd == null || !canShowInterstitial) {
      print('⏩ Interstitial not ready - Skipping');
      onCompleted();
      return;
    }

    print('🔼 Showing interstitial ad');
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        print('⏹ Interstitial dismissed');
        ad.dispose();
        _interstitialAd = null;
        _updateInterstitialTime();
        _loadInterstitialAd();
        onCompleted();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ Interstitial failed: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onCompleted();
      },
    );
    _interstitialAd!.show();
  }

  void _loadRewardedAd() {
    print('🔄 Loading rewarded ad...');
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ Rewarded ad loaded');
          _rewardedAd = ad;
          _setupRewardedAdListeners(ad);
        },
        onAdFailedToLoad: (error) {
          print('❌ Rewarded ad failed: ${error.message}');
          Future.delayed(const Duration(minutes: 5), _loadRewardedAd);
        },
      ),
    );
  }

  void _setupRewardedAdListeners(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        print('⏹ Rewarded ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ Rewarded ad failed: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
    );
  }

  void showRewardedAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onAdDismissed,
  }) {
    if (_rewardedAd != null) {
      print('🔼 Showing rewarded ad');
      _rewardedAd!.show(
        onUserEarnedReward: (_, reward) {
          print('🎉 Reward earned');
          onRewardEarned();
        },
      );
      onAdDismissed?.call();
    } else {
      print('⏳ Rewarded ad not ready - Loading new one');
      _loadRewardedAd();
    }
  }

  Widget get topBanner => _buildBannerWidget(_topBannerAd);
  Widget get bottomBanner => _buildBannerWidget(_bottomBannerAd);

  Widget _buildBannerWidget(BannerAd? ad) {
    return ad != null && _adsEnabled && _bannerAdsEnabled
        ? SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    )
        : const SizedBox.shrink();
  }

  static Future<void> openSettings(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdSettingsPage(prefs: prefs),
        ),
      );
    } catch (e) {
      print('❌ Error opening settings: $e');
    }
  }

  static Future<void> launchPrivacyPolicy() async {
    try {
      final url = Uri.parse(AdManager.privacyPolicyUrl);
      if (await canLaunchUrl(url)) {
        print('🌐 Launching privacy policy');
        await launchUrl(url);
      }
    } catch (e) {
      print('❌ Error launching privacy policy: $e');
    }
  }
}