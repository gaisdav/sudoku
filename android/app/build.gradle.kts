import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// AdMob App ID из .env в корне проекта (или .env.example)
val projectRoot: File = rootProject.projectDir.parentFile!!
val envFile: File = if (File(projectRoot, ".env").exists()) File(projectRoot, ".env") else File(projectRoot, ".env.example")
val admobAppIdAndroid = if (envFile.exists()) {
    envFile.readLines()
        .firstOrNull { line -> line.trimStart().startsWith("ADMOB_APP_ID_ANDROID=") }
        ?.substringAfter("=", "")
        ?.trim()
        ?.trim('"')
        ?: "ca-app-pub-3940256099942544~3347511713"
} else {
    "ca-app-pub-3940256099942544~3347511713"
}

// Подпись релиза для Google Play (создайте android/key.properties и keystore)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = mutableMapOf<String, String>()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.reader().useLines { lines ->
        lines.forEach { line ->
            val trimmed = line.trim()
            if (trimmed.contains("=")) {
                val parts = trimmed.split("=", limit = 2).map { it.trim() }
                if (parts.size == 2) keystoreProperties[parts[0]] = parts[1]
            }
        }
    }
}

android {
    namespace = "com.gaisdev.sudoku"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"]
                keyPassword = keystoreProperties["keyPassword"]
                storeFile = keystoreProperties["storeFile"]?.let { path ->
                    val fromRoot = rootProject.file(path)
                    if (fromRoot.exists()) fromRoot else rootProject.rootDir.parentFile?.resolve(path)
                }
                storePassword = keystoreProperties["storePassword"]
            }
        }
    }

    defaultConfig {
        applicationId = "com.gaisdev.sudoku"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["adMobApplicationId"] = admobAppIdAndroid
        // Только ARM — меньше размер AAB (x86/x86_64 только для эмулятора)
        ndk {
            abiFilters.clear()
            abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a"))
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
