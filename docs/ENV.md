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

Список ключей и описание — в файле `.env.example` в корне проекта.
