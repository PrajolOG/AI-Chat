plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter plugin must be applied after the Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Do NOT apply google-services here; we'll apply it at the bottom.
    id("com.google.gms.google-services") version "4.4.2" apply false
}

android {
    namespace = "com.example.ai_chat"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.ai_chat"
        minSdk = 23
        // flutter.targetSdkVersion, flutter.versionCode, and flutter.versionName are injected by Flutter.
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // For release builds, set up your own signing config.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Use Firebase BoM to manage Firebase library versions
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))
    implementation("com.google.firebase:firebase-analytics")
    // Add any other Firebase or dependency libraries here
}

// Apply the Google Services plugin to load firebase options from google-services.json.
apply(plugin = "com.google.gms.google-services")
