plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing config. Create android/key.properties (see docs/PLAY_STORE_RELEASE_GUIDE.md)
// before running `flutter build appbundle`; it is NOT committed to git.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(keystorePropertiesFile.inputStream())
    }
}
val hasUploadKeystore = keystorePropertiesFile.exists()

// Finds codynest-upload.jks wherever it was dropped: android/, android/app/,
// the repo root, or the user home directory.
val releaseStoreFile: File? = run {
    val value = keystoreProperties["storeFile"] as String?
    val candidates = mutableListOf<File>()
    if (!value.isNullOrBlank() && !value.startsWith("CHANGE_ME")) {
        candidates += file(value)                 // relative to android/app
        candidates += rootProject.file(value)     // relative to android/
        candidates += File(value)                 // absolute or CWD-relative
    }
    candidates += rootProject.file("codynest-upload.jks")
    candidates += rootProject.file("app/codynest-upload.jks")
    candidates += File(System.getProperty("user.home"), "codynest-upload.jks")
    candidates.firstOrNull { it.exists() }
}

android {
    namespace = "com.codynest.pos"
    // Play requires new apps to target Android 16 (API 36) since 31 Aug 2026.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.codynest.pos"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasUploadKeystore) {
                val resolved = releaseStoreFile
                if (resolved == null) {
                    throw org.gradle.api.GradleException(
                        "Upload keystore not found. Put codynest-upload.jks in android/ " +
                            "(or your home folder) and set storeFile in android/key.properties."
                    )
                }
                val storePw = keystoreProperties["storePassword"] as String?
                val keyAliasValue = keystoreProperties["keyAlias"] as String?
                val keyPw = keystoreProperties["keyPassword"] as String?
                listOf(
                    "storePassword" to storePw,
                    "keyAlias" to keyAliasValue,
                    "keyPassword" to keyPw,
                ).forEach { (name, value) ->
                    if (value.isNullOrBlank() || value == "CHANGE_ME") {
                        throw org.gradle.api.GradleException(
                            "Set $name in android/key.properties " +
                                "(template: android/key.properties.example)."
                        )
                    }
                }
                storeFile = resolved
                storePassword = storePw
                keyAlias = keyAliasValue
                keyPassword = keyPw
            }
        }
    }

    buildTypes {
        release {
            if (hasUploadKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Fail fast: a debug-signed bundle is rejected by Google Play.
                if (gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }) {
                    throw org.gradle.api.GradleException(
                        "Missing android/key.properties — create your upload keystore first " +
                            "(see docs/PLAY_STORE_RELEASE_GUIDE.md section 1.2)."
                    )
                }
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
