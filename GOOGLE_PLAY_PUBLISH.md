# Публикация Sudoku в Google Play

## 1. Регистрация и доступы

- [ ] **Аккаунт разработчика Google Play**  
  Зайти на [play.google.com/console](https://play.google.com/console) и зарегистрироваться (разовый взнос около $25).

- [ ] **Создать приложение** в консоли: «Создать приложение» → указать название, язык по умолчанию, тип (игра/приложение) и т.д.

---

## 2. Подготовка проекта

### 2.1 Сменить Application ID

Сейчас стоит `com.example.sudoku`. Нужен уникальный ID, например `com.вашдомен.sudoku` или `com.вашеимя.sudoku`.

**Файл:** `android/app/build.gradle.kts`

```kotlin
namespace = "com.yourname.sudoku"
// ...
applicationId = "com.yourname.sudoku"
```

Также переименовать пакет в `android/app/src/main/kotlin/...` (папки и package в MainActivity.kt), чтобы совпадал с `namespace`.

### 2.2 Ключ для подписи (signing)

1. **Создать keystore** (один раз, хранить в надёжном месте):

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Указать пароли и данные (имя, организация и т.д.). Файл `upload-keystore.jks` и пароли нельзя терять — без них нельзя обновлять приложение в Play.

2. **Создать вручную файл `android/key.properties`** (его нет в репозитории; в `android/.gitignore` он уже указан, в git не попадёт):

```properties
storePassword=ваш_пароль_хранилища
keyPassword=ваш_пароль_ключа
keyAlias=upload
storeFile=../upload-keystore.jks
```

**Откуда пароли:** вы сами их задали при создании keystore командой `keytool`. `storePassword` — тот пароль, что вводили на вопрос «Enter keystore password». `keyPassword` — пароль для ключа (на вопрос «Enter key password for <upload>»; если нажали Enter и оставили тот же — совпадает с `storePassword`). Подставьте в файл эти свои пароли.

Путь `storeFile` — относительно папки `android/` или абсолютный путь к `.jks`.

3. **Подключить подпись в `android/app/build.gradle.kts`** — см. раздел 3 ниже.

### 2.3 Версия и название

- **Версия:** в `pubspec.yaml` уже `version: 1.0.0+1` (1.0.0 — versionName, 1 — versionCode). При следующих релизах увеличивать, например `1.0.1+2`.

- **Название в системе:** в `android/app/src/main/AndroidManifest.xml` уже `android:label="sudoku"`. Можно заменить на «Sudoku» или любое отображаемое имя.

### 2.4 Иконка и скриншоты

- Иконка: заменить `android/app/src/main/res/mipmap-*/ic_launcher.png` на свою (рекомендуется 1024×1024 для Play и стандартные размеры для mipmap).
- Скриншоты для листинга: сделать с телефона/эмулятора (минимум 2, лучше 4–8) для телефона и при необходимости для планшета.

---

## 3. Настройка подписи в build.gradle.kts

В **`android/app/build.gradle.kts`** в начале файла (после `plugins { ... }`):

```kotlin
// Читаем key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

Для `storeFile` в `key.properties` лучше указать полный путь к `.jks` или путь относительно корня проекта, и в коде использовать `file(keystoreProperties["storeFile"])` (при необходимости заменить `../` на путь от `android/`).

---

## 4. Сборка релизного AAB

Google Play принимает **Android App Bundle (.aab)**, не APK.

```bash
flutter build appbundle
```

Чтобы уменьшить размер (обфускация Dart + отключение лишних символов, обычно −15–25%):

```bash
flutter build appbundle --obfuscate --split-debug-info=build/app/outputs/symbols
```

Папку `build/app/outputs/symbols` сохраните: она нужна для расшифровки стектрейсов при крашах. В репозиторий не коммитить.

Готовый файл: `build/app/outputs/bundle/release/app-release.aab`.

**Уже настроено в проекте:** в `android/app/build.gradle.kts` для релиза включены только ARM-архитектуры (`arm64-v8a`, `armeabi-v7a`), без x86/x86_64 — так AAB меньше, а на реальных устройствах всё работает (эмулятор для такого билда не подойдёт).

Проверка на устройстве (APK из AAB для теста):

```bash
flutter build apk --release
```

---

## 5. Заполнение листинга в Google Play Console

- **Название приложения** и **краткое описание** (до 80 символов).
- **Полное описание** (до 4000 символов).
- **Категория:** Игры → Головоломки (или подходящая).
- **Иконка 512×512** и **скриншоты** (обязательно).
- **Контент-рейтинг:** пройти анкету (обычно для Sudoku — для всех возрастов).
- **Политика конфиденциальности:** если приложение собирает данные (например, аналитика), нужна ссылка на политику. Для простой офлайн-игры иногда можно указать, что данные не собираются (по актуальным правилам консоли).
- **Целевая аудитория и реклама:** указать возраст и есть ли реклама (если нет — выбрать «Нет рекламы»).

---

## 6. Загрузка и публикация

1. В консоли: **Release** → **Production** (или тестовая дорожка).
2. **Create new release** → загрузить `app-release.aab`.
3. Указать **Release name** (например `1.0.0 (1)`) и при необходимости **Release notes**.
4. **Save** → **Review release** → отправить на проверку.

Проверка обычно занимает от нескольких часов до нескольких дней. После одобрения приложение появится в Google Play (если выбран полный релиз в Production).

---

## Краткий чеклист

| Шаг | Действие |
|-----|----------|
| 1 | Аккаунт разработчика Google Play |
| 2 | Сменить `applicationId` и namespace с `com.example.sudoku` |
| 3 | Создать keystore и настроить `key.properties` + signing в build.gradle.kts |
| 4 | Иконка, скриншоты, описание, контент-рейтинг |
| 5 | `flutter build appbundle` |
| 6 | Загрузить AAB в консоль и отправить на проверку |

После первой публикации для обновлений: увеличить версию в `pubspec.yaml`, снова собрать AAB и загрузить новую версию в том же приложении в консоли.
