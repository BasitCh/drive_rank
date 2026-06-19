import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing config loaded from android/key.properties — this file is
// .gitignore'd. To set it up locally, create:
//
//   storePassword=...
//   keyPassword=...
//   keyAlias=upload
//   storeFile=/Users/you/keystores/driverank-upload.jks
//
// On Codemagic the keystore is provided through the `keystore_reference`
// integration in codemagic.yaml — this block silently falls back to the
// debug keys when the file isn't present so `flutter run` keeps working.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.bytse.drive_rank"
    compileSdk = flutter.compileSdkVersion
    // Pinned manually instead of using `flutter.ndkVersion` because the
    // Flutter 3.41 default (28.2.13676358) has a corrupted local install on
    // some dev machines. 29.x is the latest fully-installed NDK in this
    // project's environment. To re-align with Flutter's default, install
    // the canonical NDK with:
    //   sdkmanager --install "ndk;${flutter.ndkVersion}"
    // and switch the line below back to `flutter.ndkVersion`.
    ndkVersion = "29.0.13599879"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (it ships time-zone
        // code that uses java.time APIs which only exist natively on
        // API 26+; desugaring backfills them down to our minSdk 21).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.bytse.drive_rank"
        // Drift + sqlite3_flutter_libs both require minSdk 21. Geolocator
        // is happy down to 16. We let Flutter pick the floor.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Allow apps that link to Firebase to use a backwards-compatible
        // multidex setup on minSdk 21 builds.
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use the release config when key.properties exists, otherwise
            // fall back to debug so `flutter run --release` still works on
            // a fresh checkout.
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            // No applicationIdSuffix on purpose: the suffix gives debug
            // a different package name (com.bytse.drive_rank.debug) which
            // breaks google-services.json — flutterfire only registered
            // the base id. Keep `-debug` in the version name so we can
            // still tell builds apart on a tester device.
            versionNameSuffix = "-debug"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring runtime — paired with
    // `isCoreLibraryDesugaringEnabled = true` above. Required by
    // flutter_local_notifications. The 2.1.x version line is what
    // the plugin pins to as of mid-2026 — bump only when the plugin
    // changelog explicitly says to.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
