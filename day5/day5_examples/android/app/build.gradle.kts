// ============================================================
// الدرس 8 (Release): Flavors (dev / prod) + التوقيع (Signing) على Android
// (والدرس 6: desugaring تطلبه flutter_local_notifications)
// في Dart: lib/lessons/08_flavors_signing.dart
// ============================================================
//
// التشغيل:
//   flutter run --flavor dev        ← com.workshop.day5_examples.dev  "Day5 Dev"
//   flutter run --flavor prod       ← com.workshop.day5_examples      "Day5"
//   flutter build appbundle --flavor prod --release
// (pubspec.yaml فيه default-flavor: dev ← flutter run بدون --flavor = dev)

import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ------------------------------------------------------------
// التوقيع: نقرأ android/key.properties إن وُجد (لا يُرفع إلى Git أبداً!)
// انسخ android/key.properties.example إلى key.properties واملأ القيم
// ------------------------------------------------------------
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.workshop.day5_examples"
    // flutter_local_notifications 23 و permission_handler_android 14 تتطلبان 37
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // الدرس 6: مطلوب لـ flutter_local_notifications (java.time على الأجهزة القديمة)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.workshop.day5_examples"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // من pubspec.yaml: version: 1.0.0+1 ← versionName 1.0.0 و versionCode 1
        // ⚠️ كل رفع إلى Google Play يحتاج versionCode أكبر من السابق
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    // ------------------------------------------------------------
    // Flavors: نسختان من نفس الكود تُثبّتان معاً على نفس الجهاز
    // ------------------------------------------------------------
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev" // معرّف مختلف ← تطبيقان منفصلان
            versionNameSuffix = "-dev"
            manifestPlaceholders["appLabel"] = "Day5 Dev" // اسم التطبيق على الشاشة
        }
        create("prod") {
            dimension = "env"
            manifestPlaceholders["appLabel"] = "Day5"
        }
    }

    buildTypes {
        release {
            // مع key.properties: توقيع الإنتاج. بدونه: مفتاح debug ليعمل flutter run --release
            // (Google Play يرفض أي ملف موقَّع بمفتاح debug)
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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

dependencies {
    // الدرس 6: مكتبة desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // الدرس 4: كود Pigeon المولَّد يستخدم coroutines لدوال @async (suspend)
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
}
