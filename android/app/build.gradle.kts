import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Lab 13: release signing. key.properties and the .jks are gitignored.
val keystoreProperties = Properties().apply {
    rootProject.file("key.properties").takeIf { it.exists() }?.inputStream()?.use { load(it) }
}

android {
    // This app has no C/C++ code. Point CMake at Flutter's empty fallback so
    // AGP does not try to auto-install an NDK through sdkmanager.
    externalNativeBuild {
        cmake {
            val localProps = Properties().apply {
                rootProject.file("local.properties").inputStream().use { load(it) }
            }
            val flutterRoot = localProps.getProperty("flutter.sdk")
            path = file("$flutterRoot/packages/flutter_tools/gradle/src/main/scripts/CMakeLists.txt")
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: "upload"
            keyPassword = keystoreProperties["keyPassword"] as String? ?: ""
            storePassword = keystoreProperties["storePassword"] as String? ?: ""
            val path = keystoreProperties["storeFile"] as String?
            if (path != null) storeFile = file(path)
        }
    }

    namespace = "gh.edu.umat.lab13_release"
    compileSdk = flutter.compileSdkVersion
    // No NDK is needed (no native C/C++ code). Leaving ndkVersion unset makes
    // Flutter use its synthetic CMake fallback instead of invoking sdkmanager.

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "gh.edu.umat.lab13_release"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signed with the upload key from android/key.properties.
            signingConfig = signingConfigs.getByName("release")
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
