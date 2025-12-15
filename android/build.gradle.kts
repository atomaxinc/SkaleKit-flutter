plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

group = "com.atomaxinc.skalekit"
version = "1.0.0"

android {
    namespace = "com.atomaxinc.skalekit.flutter"
    compileSdk = 34

    defaultConfig {
        minSdk = 21
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")
    implementation("androidx.core:core-ktx:1.12.0")

    // SkaleKit AAR - Include from local libs folder
    implementation(files("libs/skalekit-1.0.0.aar"))
}
