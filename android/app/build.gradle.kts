import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val releaseSigningPropertiesFile = rootProject.file("key.properties")
val releaseSigningProperties = Properties().apply {
    if (releaseSigningPropertiesFile.exists()) {
        releaseSigningPropertiesFile.inputStream().use { load(it) }
    }
}
val requiredSigningProperties = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val releaseSigningConfigured = requiredSigningProperties.all {
    !releaseSigningProperties.getProperty(it).isNullOrBlank()
}

if (releaseSigningPropertiesFile.exists() && !releaseSigningConfigured) {
    throw GradleException(
        "android/key.properties must define storeFile, storePassword, keyAlias, and keyPassword."
    )
}

android {
    namespace = "com.example.absensi_app"
    compileSdk = 36 

    ndkVersion = "28.2.13676358" 

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.absensi_app"
        
        // Paksa ke 23 biar library update & firebase gak bentrok
        minSdk = flutter.minSdkVersion
        targetSdk = 36 
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    if (releaseSigningConfigured) {
        signingConfigs {
            create("release") {
                keyAlias = releaseSigningProperties.getProperty("keyAlias")
                keyPassword = releaseSigningProperties.getProperty("keyPassword")
                storeFile = rootProject.file(releaseSigningProperties.getProperty("storeFile"))
                storePassword = releaseSigningProperties.getProperty("storePassword")
            }
        }
    } else {
        logger.warn(
            "Release signing is not configured. Add android/key.properties before creating a release bundle."
        )
    }

    buildTypes {
        release {
            // Aktifkan R8 untuk proteksi kode (obfuscation) & ukuran APK lebih kecil
            isMinifyEnabled = true 
            isShrinkResources = true
            
            signingConfig = if (releaseSigningConfigured) {
                signingConfigs.getByName("release")
            } else {
                null
            }
            
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

tasks.configureEach {
    if (name == "bundleRelease" || name == "assembleRelease") {
        doFirst {
            if (!releaseSigningConfigured) {
                throw GradleException(
                    "Release signing is not configured. Create android/key.properties using the documented release keystore settings."
                )
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
