<<<<<<< HEAD
=======
// android/build.gradle.kts  (Project-level)

import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

// ✅ ให้ Gradle รู้จัก Google Services plugin (จำเป็นสำหรับ Firebase)
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

// ✅ ใช้รีโปมาตรฐานทั้งหมด
>>>>>>> c3bd551 (Initial commit: help_care app)
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

<<<<<<< HEAD
=======
// ✅ ย้ายไดเรกทอรี build ไปโฟลเดอร์บนสุด (ตามที่โปรเจกต์คุณตั้งไว้)
>>>>>>> c3bd551 (Initial commit: help_care app)
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
<<<<<<< HEAD
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

=======
    // ตั้งค่า buildDir ของแต่ละโมดูลให้ไปอยู่ใต้โฟลเดอร์ใหม่
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    layout.buildDirectory.value(newSubprojectBuildDir)

    // ให้แน่ใจว่าโมดูล :app ถูก evaluate ก่อน (ตามไฟล์เดิมของคุณ)
    evaluationDependsOn(":app")
}

// ✅ งาน clean โปรเจกต์
>>>>>>> c3bd551 (Initial commit: help_care app)
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
