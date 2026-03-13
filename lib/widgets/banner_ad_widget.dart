import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_colors.dart';
import '../utils/vibration_helper.dart';
import '../ads_platform.dart';

/// Баннерная реклама (anchored adaptive) для размещения внизу экрана.
/// На Android/iOS использует ADMOB_BANNER_ID_* из .env; на Web и десктопе не показывается.
///
/// Если [collapsible] true, в правом верхнем углу баннера — небольшая плашка со стрелкой (▼ свернуть, ▲ развернуть).
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

  static const _collapseChipPadding = 6.0;

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

    if (_expanded) {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topRight,
        children: [
          banner,
          Positioned(
            top: _collapseChipPadding,
            right: _collapseChipPadding,
            child: _CollapseChip(
              arrowDown: true,
              onTap: () {
                hapticSelection();
                setState(() => _expanded = false);
              },
            ),
          ),
        ],
      );
    }

    return _CollapseChip(
      arrowDown: false,
      onTap: () {
        hapticSelection();
        setState(() => _expanded = true);
      },
    );
  }
}

class _CollapseChip extends StatelessWidget {
  const _CollapseChip({
    required this.arrowDown,
    required this.onTap,
  });

  final bool arrowDown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.chipBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Icon(
            arrowDown ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
            size: 22,
            color: colors.textMutedDark,
          ),
        ),
      ),
    );
  }
}
