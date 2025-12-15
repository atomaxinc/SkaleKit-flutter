plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

group = "com.atomaxinc.skalekit"
version = "1.0.0"

android {
    namespace = "com.atomaxinc.skalekit"
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

repositories {
    maven {
        url = uri("${projectDir}/repo")
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")
    implementation("androidx.core:core-ktx:1.12.0")

    // SkaleKit AAR from local Maven repository - use 'api' to expose to consumers
    api("com.atomaxinc:skalekit:1.0.0")
}
