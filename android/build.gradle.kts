allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("${project(":flutter_background_geolocation").projectDir}/libs")
        }
    }
}

// BGL (included for iOS Dart) expects play-services-location 20.x where
// FusedLocationProviderClient is a class. Newer versions use an interface and
// crash TransistorSoft native code at runtime if forced higher.
extra["playServicesLocationVersion"] = "20.0.0"

subprojects {
    configurations.configureEach {
        resolutionStrategy {
            force("com.google.android.gms:play-services-location:20.0.0")
        }
    }
}

subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
            if (compileSdk != null && compileSdk!! < 36) {
                compileSdk = 36
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
