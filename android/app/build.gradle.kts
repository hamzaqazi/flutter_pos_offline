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
//
// NOTE: no java.util.Properties here — Gradle's Kotlin script JVM does not
// import java.* packages by default, which breaks the standard Flutter snippet.
// Plain "key=value" parsing keeps the file format identical.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties: Map<String, String> =
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile
            .readLines()
            .map { it.trim() }
            .filter { it.isNotEmpty() && !it.startsWith("#") && it.contains("=") }
            .associate { line ->
                val idx = line.indexOf('=')
                line.substring(0, idx).trim() to line.substring(idx + 1).trim()
            }
    } else {
        emptyMap()
    }
val hasUploadKeystore = keystorePropertiesFile.exists()

// Finds codynest-upload.jks wherever it was dropped: android/, android/app/,
// the repo root, or the user's home directory. Paths are resolved against the
// android/ project (rootProject), and absolute paths work too.
val releaseStoreFile = buildList {
    val configured = keystoreProperties["storeFile"]
    if (!configured.isNullOrBlank() && !configured.startsWith("CHANGE_ME")) {
        add(configured)
    }
    add("codynest-upload.jks")
    add("app/codynest-upload.jks")
    add(System.getProperty("user.home") + "/codynest-upload.jks")
}.map { rootProject.file(it) }.firstOrNull { it.exists() }

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
                val storePw = keystoreProperties["storePassword"]
                val alias = keystoreProperties["keyAlias"]
                val keyPw = keystoreProperties["keyPassword"]
                for (entry in listOf(
                    "storePassword" to storePw,
                    "keyAlias" to alias,
                    "keyPassword" to keyPw,
                )) {
                    if (entry.second.isNullOrBlank() || entry.second == "CHANGE_ME") {
                        throw org.gradle.api.GradleException(
                            "Set ${entry.first} in android/key.properties " +
                                "(template: android/key.properties.example)."
                        )
                    }
                }
                storeFile = resolved
                storePassword = storePw
                keyAlias = alias
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
                val buildingRelease = gradle.startParameter.taskNames.any {
                    it.contains("Release", ignoreCase = true)
                }
                if (buildingRelease) {
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
