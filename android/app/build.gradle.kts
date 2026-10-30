import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties()
val signingPropertiesFile = rootProject.file("key.properties")

if (signingPropertiesFile.exists()) {
    FileInputStream(signingPropertiesFile).use {
        signingProperties.load(it)
    }
}

android {
    namespace = "com.agdevelps.reality_shift"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.agdevelps.reality_shift"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            require(signingPropertiesFile.exists()) {
                "Missing android/key.properties. Configure release signing first."
            }

            storeFile = file(
                signingProperties.getProperty("storeFile")
                    ?: error("Missing storeFile in key.properties")
            )

            storePassword = signingProperties.getProperty("storePassword")
                ?: error("Missing storePassword in key.properties")

            keyAlias = signingProperties.getProperty("keyAlias")
                ?: error("Missing keyAlias in key.properties")

            keyPassword = signingProperties.getProperty("keyPassword")
                ?: error("Missing keyPassword in key.properties")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
