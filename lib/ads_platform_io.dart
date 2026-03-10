import 'dart:io';

import 'env.dart';

/// ID баннера для текущей платформы (только Android/iOS).
String get bannerAdUnitId {
  if (Platform.isIOS) return Env.admobBannerIdIos;
  return Env.admobBannerIdAndroid;
}
