plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.sokofiti.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.sokofiti.app"
        minSdk = 21  // Android 5.0 (API level 21)
        targetSdk = 33  // Android 13 (API level 33) - more compatible
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Enable debugging features
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        // Add network security config for debug builds
        manifestPlaceholders["usesCleartextTraffic"] = "true"

        // Add compatibility flags
        manifestPlaceholders["allowBackup"] = "true"
        manifestPlaceholders["requestLegacyExternalStorage"] = "true"
    }

    buildTypes {
        debug {
            isDebuggable = true
            isMinifyEnabled = false
            versionNameSuffix = "-debug"

            // Enable network debugging
            manifestPlaceholders["usesCleartextTraffic"] = "true"

            // Add debug-specific configurations
            buildConfigField("String", "API_BASE_URL", "\"https://sokofiti.ke\"")
            buildConfigField("boolean", "DEBUG_MODE", "true")
        }

        release {
            isDebuggable = false
            isMinifyEnabled = true
            isShrinkResources = true

            // Use debug signing for now (should be replaced with proper release signing)
            signingConfig = signingConfigs.getByName("debug")

            // Production configurations
            buildConfigField("String", "API_BASE_URL", "\"https://sokofiti.ke\"")
            buildConfigField("boolean", "DEBUG_MODE", "false")

            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
