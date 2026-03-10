import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads_platform.dart';

/// Баннерная реклама (anchored adaptive) для размещения внизу экрана.
/// На Android/iOS использует ADMOB_BANNER_ID_* из .env; на Web и десктопе не показывается.
///
/// Если [collapsible] true, показывается тонкая полоска «▲ Ad» в свёрнутом виде;
/// по нажатию баннер разворачивается, сверху появляется «▼ Hide» для сворачивания.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key, this.collapsible = false});

  /// На экране игры баннер можно свернуть, чтобы освободить место.
  final bool collapsible;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _expanded = true;

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
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (size == null || !mounted) return;

      final ad = BannerAd(
        adUnitId: adUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad loadedAd) {
            if (mounted) {
              setState(() {
                _bannerAd = loadedAd as BannerAd;
                _isLoaded = true;
              });
            }
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

  static const _collapsedBarHeight = 36.0;

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    final ad = _bannerAd!;
    final banner = SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );

    if (!widget.collapsible) {
      return banner;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_expanded) ...[
          _CollapseBar(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = false);
            },
            showCollapse: true,
          ),
          banner,
        ] else ...[
          _CollapseBar(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = true);
            },
            showCollapse: false,
          ),
        ],
      ],
    );
  }
}

class _CollapseBar extends StatelessWidget {
  const _CollapseBar({
    required this.onTap,
    required this.showCollapse,
  });

  final VoidCallback onTap;
  /// true = "Hide" (collapse), false = "Ad" (expand)
  final bool showCollapse;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade200,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _BannerAdWidgetState._collapsedBarHeight,
          width: double.infinity,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showCollapse ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  showCollapse ? 'Hide' : 'Ad',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
