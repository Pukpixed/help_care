plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // ✅ ต้องตรงกับ Firebase
    namespace = "com.example.helpcare"

    // ✅ plugin บังคับให้ใช้สูง
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        // ✅ ต้องตรงกับ Firebase
        applicationId = "com.example.helpcare"

        // ✅ รองรับ Android กว้างสุด
        minSdk = flutter.minSdkVersion
        targetSdk = 34   // หรือ 36 ก็ได้

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }

        release {
            // ✅ แจก APK ปิดไว้ก่อน
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ จำเป็นสำหรับ Java 17
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
