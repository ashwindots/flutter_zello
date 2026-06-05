group = "com.zello.flutter"
version = "0.1.0"

buildscript {
    val kotlinVersion = "1.9.22"
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // TODO: add the Zello Maven repo / Artifactory URL provided with your
        // Zello Work subscription, e.g.:
        // maven { url = uri("https://maven.zello.com/release") }
    }
}

apply(plugin = "com.android.library")
apply(plugin = "kotlin-android")

android {
    namespace = "com.zello.flutter"
    compileSdk = 34

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        minSdk = 23
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    // TODO: declare the Zello Android SDK dependency once you have access.
    // Example (replace with the exact coords from your Zello Work portal):
    // implementation("com.zello:zello-channel-sdk:<version>")
    //   or a local file:
    // implementation(files("libs/zello-channel-sdk.aar"))
}
