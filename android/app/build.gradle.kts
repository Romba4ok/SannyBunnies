plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

// Загрузка key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.example.sannybunnies"
    compileSdk = flutter.compileSdkVersion
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
        applicationId = "com.example.sannybunnies"
        minSdk = flutter.minSdkVersion       // должно соответствовать предыдущему релизу
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
    }


    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"]?.toString() ?: ""
            keyPassword = keystoreProperties["keyPassword"]?.toString() ?: ""
            storePassword = keystoreProperties["storePassword"]?.toString() ?: ""
            val storeFilePath = keystoreProperties["storeFile"]?.toString()
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = file(storeFilePath)
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.20")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("com.google.android.gms:play-services-auth:20.7.0")
}
