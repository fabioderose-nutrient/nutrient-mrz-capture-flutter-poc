plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.nutrient.poc.mrzcapture"
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
        applicationId = "io.nutrient.poc.mrzcapture"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Nutrient Android SDK — OCR module (on-device text recognition).
    // Same major version as the one pulled by nutrient_flutter to avoid conflicts.
    val nutrient = "11.2.1"
    implementation("io.nutrient:nutrient-ocr:$nutrient")
    implementation("io.nutrient:nutrient-ocr-english:$nutrient")
    implementation("io.reactivex.rxjava3:rxjava:3.1.8")
}

flutter {
    source = "../.."
}
