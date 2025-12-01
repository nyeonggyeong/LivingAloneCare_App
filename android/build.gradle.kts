// android/build.gradle.kts (프로젝트 레벨)
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Android Gradle 플러그인
        classpath("com.android.tools.build:gradle:8.1.1")
        
        // Kotlin Gradle 플러그인
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22") 

        classpath("com.google.gms:google-services:4.4.0") 
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}