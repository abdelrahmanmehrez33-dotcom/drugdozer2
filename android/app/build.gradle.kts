plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.drugdozer.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.drugdozer.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 2
        versionName = "2.0.0"
        
        // Enable multidex for larger apps
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Enable minification and resource shrinking for production
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // TODO: Add your own signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")
        }
        
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    // Enable view binding
    buildFeatures {
        viewBinding = true
    }
    
    // Lint options
    lint {
        disable += "InvalidPackage"
        checkReleaseBuilds = false
    }

    dependencies {
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
        
        // WorkManager for background tasks
        implementation("androidx.work:work-runtime-ktx:2.9.0")
        
        // Google Play Services for location
        implementation("com.google.android.gms:play-services-location:21.0.1")
        implementation("com.google.android.gms:play-services-maps:18.2.0")
    }
}

flutter {
    source = "../.."
}
