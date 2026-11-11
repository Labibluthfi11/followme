import java.util.Properties
import java.security.KeyStore
import java.security.MessageDigest
import java.io.FileInputStream

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
val expectedReleaseCertificateSha256 =
    "ab2e0c26fa817a7468c4f11db7d3b1dc62323bab565526c0f12b7b0a2f761edf"
val releaseSigningConfigured = requiredSigningProperties.all {
    !releaseSigningProperties.getProperty(it).isNullOrBlank()
}

fun releaseCertificateSha256(): String {
    val storePassword = releaseSigningProperties.getProperty("storePassword")
    val keyAlias = releaseSigningProperties.getProperty("keyAlias")
    val storeFile = rootProject.file(releaseSigningProperties.getProperty("storeFile"))
    if (!storeFile.isFile) {
        throw GradleException("Release keystore file was not found: ${storeFile.path}")
    }

    val keystore = KeyStore.getInstance("JKS")
    FileInputStream(storeFile).use { keystore.load(it, storePassword.toCharArray()) }
    val certificate = keystore.getCertificate(keyAlias)
        ?: throw GradleException("Release certificate alias was not found in the keystore.")
    return MessageDigest.getInstance("SHA-256")
        .digest(certificate.encoded)
        .joinToString("") { "%02x".format(it) }
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
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
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
            val actualCertificateSha256 = releaseCertificateSha256()
            if (actualCertificateSha256 != expectedReleaseCertificateSha256) {
                throw GradleException(
                    "Release signing certificate changed. APK updates require the existing release key. " +
                        "Expected SHA-256 $expectedReleaseCertificateSha256, got $actualCertificateSha256."
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
