// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.helpcare"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.helpcare"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // เผื่อโปรเจกต์ใหญ่ + Firebase หลายตัว (ปลอดภัยไว้ก่อน)
        multiDexEnabled = true
    }

    // Java 17 + desugaring
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // (ไม่จำเป็นต้องกำหนด signingConfig เองใน release ถ้ายังไม่ได้ตั้ง keystore จริง)
    buildTypes {
        debug {
            // ค่าเริ่มต้นก็ได้ แต่อันนี้ชัดเจน
            isMinifyEnabled = false
            isShrinkResources = false
        }

        release {
            // แนะนำให้ปิดไว้ก่อนตอนกำลังพัฒนา (กัน R8/Proguard พัง)
            isMinifyEnabled = false
            isShrinkResources = false

            // ❌ ไม่แนะนำให้ใช้ debug keystore สำหรับ release
            // ถ้ายังไม่มี keystore จริง ให้ลบบรรทัด signingConfig ออก
            // signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // desugaring (>= 2.1.4)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
