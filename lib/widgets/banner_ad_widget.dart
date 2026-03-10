import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads_platform.dart';

/// Баннерная реклама (anchored adaptive) для размещения внизу экрана.
/// На Android/iOS использует ADMOB_BANNER_ID_* из .env; на Web и десктопе не показывается.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd != null) return;
    _loadAd();
  }

  Future<void> _loadAd() async {
    final adUnitId = bannerAdUnitId;
    if (adUnitId.isEmpty) return;
    try {
      final width = MediaQuery.sizeOf(context).width.truncate();
      final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (size == null || !mounted) return;

      final ad = BannerAd(
        adUnitId: adUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad loadedAd) {
            if (mounted) setState(() {
              _bannerAd = loadedAd as BannerAd;
              _isLoaded = true;
            });
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            debugPrint('BannerAd failed to load: $error');
            ad.dispose();
          },
        ),
      );
      await ad.load();
    } catch (_) {
      // На Web и macOS плагин не реализован — просто не показываем баннер
    }
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
    final ad = _bannerAd!;
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
