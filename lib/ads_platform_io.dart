import 'dart:io';

import 'env.dart';

/// ID баннера для текущей платформы (только Android/iOS).
String get bannerAdUnitId {
  if (Platform.isIOS) return Env.admobBannerIdIos;
  return Env.admobBannerIdAndroid;
}

/// ID вознаграждаемой рекламы для текущей платформы.
String get rewardedAdUnitId {
  if (Platform.isIOS) return Env.admobRewardedIdIos;
  return Env.admobRewardedIdAndroid;
}

/// ID межстраничной рекламы для текущей платформы.
String get interstitialAdUnitId {
  if (Platform.isIOS) return Env.admobInterstitialIdIos;
  return Env.admobInterstitialIdAndroid;
}

/// ID рекламы при открытии приложения (App Open).
String get appOpenAdUnitId {
  if (Platform.isIOS) return Env.admobAppOpenIdIos;
  return Env.admobAppOpenIdAndroid;
}
