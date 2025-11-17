// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    // FlutterFire / Google Services
    id("com.google.gms.google-services")
    id("kotlin-android")
    // ต้องตามหลัง android + kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // ชื่อ package หลักของแอป (ให้ใช้ตัวเดียวกันทั้งโปรเจกต์)
    namespace = "com.example.helpcare"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.helpcare"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ ใช้ Java 17 + เปิด desugaring
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // ยังใช้ debug keystore ไปก่อน ให้รัน --release ได้
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ สำหรับ desugaring (ต้อง ≥ 2.1.4)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
