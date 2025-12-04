plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    
    // Google Services 플러그인 추가 (Firebase 설정 필수)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.livingalonecare_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.bosongi.livingalonecare" 
        
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Firebase 의존성 추가
dependencies {
    // Firebase BoM (Bill of Materials)을 사용하여 버전을 관리합니다.
    implementation(platform("com.google.firebase:firebase-bom:32.7.0")) 
    // Firebase Authentication 모듈을 추가합니다.
    implementation("com.google.firebase:firebase-auth")
    
    // 기본 의존성
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}