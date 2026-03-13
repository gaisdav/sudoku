import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'config/app_colors.dart';
import 'l10n/app_localizations.dart';
import 'providers/accent_color_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'screens/home_screen.dart';
import 'services/app_open_ad_service.dart';
import 'services/game_storage.dart';
import 'services/interstitial_ad_service.dart';
import 'services/rewarded_ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Загрузка .env (если добавлен в assets) или .env.example с тестовыми значениями
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    await dotenv.load(fileName: '.env.example');
  }
  await GameStorage.init();
  // Инициализация AdMob в фоне — не блокируем показ UI (иначе 10+ сек чёрный экран в release).
  try {
    AppOpenAdService.setAdsInitFuture(MobileAds.instance.initialize());
  } catch (_) {}
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: SudokuApp()));
}

class SudokuApp extends ConsumerStatefulWidget {
  const SudokuApp({super.key});

  @override
  ConsumerState<SudokuApp> createState() => _SudokuAppState();
}

class _SudokuAppState extends ConsumerState<SudokuApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppOpenAdService.maybeShowColdStart();
      AppOpenAdService.runWhenAdsReady(() {
        InterstitialAdService.preload();
        preloadRewardedAd();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        AppOpenAdService.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        AppOpenAdService.maybeShowResume();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final accentIndex = ref.watch(accentIndexProvider).clamp(0, accentColorOptions.length - 1);
    final accentColor = accentColorOptions[accentIndex];
    final lightColors = AppColors.lightWithAccent(accentColor);
    final darkColors = AppColors.darkWithAccent(accentColor);
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'Sudoku',
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.light,
          primary: accentColor,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        extensions: [lightColors],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
          primary: accentColor,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        extensions: [darkColors],
      ),
      home: const HomeScreen(),
    );
  }
}

