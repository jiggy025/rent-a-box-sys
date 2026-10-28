plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rentabox.ledger.rent_a_box_sys"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.rentabox.ledger.rent_a_box_sys"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // The cloud build (.github/workflows/android-apk.yml) hands over the same keystore the installed
    // app was signed with, so its APK installs as an update and keeps the shop's local data.
    // Without those variables (a local build), release falls back to this machine's debug key as before.
    val ciKeystore = System.getenv("ESPASYO_KEYSTORE_PATH")
    signingConfigs {
        if (ciKeystore != null) {
            create("ci") {
                storeFile = file(ciKeystore)
                storePassword = System.getenv("ESPASYO_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ESPASYO_KEY_ALIAS")
                keyPassword = System.getenv("ESPASYO_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (ciKeystore != null) signingConfigs.getByName("ci") else signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
