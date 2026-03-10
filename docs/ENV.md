# Переменные окружения (.env)

Чувствительные данные (ID рекламы AdMob и т.п.) хранятся в `.env`. Файл **не коммитится** (см. `.gitignore`).

**Тест vs прод:** в `.env.example` лежат **тестовые** ID Google (для разработки). В своём `.env` можно указать **боевые** ID из консоли [AdMob](https://admob.google.com) (приложение и рекламные блоки) — они для продакшена. До публикации приложения в Store лучше использовать тестовые ID, чтобы не нарушать политики.

## Настройка

1. Скопируйте пример в локальный файл:
   ```bash
   cp .env.example .env
   ```
2. Откройте `.env` и подставьте свои значения (App ID и Ad unit ID из консоли AdMob).
3. Чтобы приложение подхватывало `.env` при сборке, добавьте его в ресурсы в `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - .env.example
       - .env      # добавьте эту строку, когда создали .env
   ```

Если `.env` не создан или не добавлен в `assets`, приложение загружает `.env.example` (в нём тестовые ID AdMob для разработки).

## Использование в коде

- Через класс **`Env`** (см. `lib/env.dart`):
  ```dart
  import 'package:sudoku/env.dart';

  final appId = Env.admobAppIdAndroid;  // или Env.get('ADMOB_APP_ID_ANDROID')
  ```
- Значения из **`--dart-define`** имеют приоритет над `.env`, удобно для CI/релиза:
  ```bash
  flutter build apk --dart-define=ADMOB_APP_ID_ANDROID=ca-app-pub-xxx
  ```

## Ключи в .env.example

- **ID рекламы AdMob** (баннер, interstitial, rewarded, app open) — список и описание в `.env.example`.
- **Параметры управления рекламой** (интервалы, «каждое N-е» для Interstitial и App Open) — тоже в `.env.example` (блок с комментариями). В коде они читаются через класс **`AdConfig`** (`lib/config/ad_config.dart`), например:
  ```dart
  import 'package:sudoku/config/ad_config.dart';

  final intervalMin = AdConfig.interstitialMinIntervalMinutes;
  final everyNth = AdConfig.interstitialEveryNthContinue;
  ```
  При реализации Interstitial и App Open используйте `AdConfig`, чтобы лимиты брались из .env (для отладки можно задать 0 и 1).
