import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
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
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }
}

flutter {
    source = "../.."
}
