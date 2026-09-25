import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.aidlink_app"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    // Flutter adds an empty CMake project only to download the NDK. Its timing
    // logs can fail with file locks on this Windows builder. Opt out only when
    // the required NDK is already installed, without skipping real native code.
    if (System.getenv("AIDLINK_SKIP_NDK_BOOTSTRAP") == "1") {
        val bootstrapPath = externalNativeBuild.cmake.path
            ?.invariantSeparatorsPath
        require(bootstrapPath?.endsWith(
            "/flutter_tools/gradle/src/main/scripts/CMakeLists.txt"
        ) == true) { "Only Flutter's empty NDK bootstrap may be skipped." }
        val localProperties = Properties().apply {
            rootProject.file("local.properties").inputStream().use { load(it) }
        }
        val sdkPath = requireNotNull(localProperties.getProperty("sdk.dir"))
        require(file("$sdkPath/ndk/${flutter.ndkVersion}/source.properties").isFile) {
            "Install NDK ${flutter.ndkVersion} before skipping its bootstrap."
        }
        externalNativeBuild.cmake.path = null
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.aidlink_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
