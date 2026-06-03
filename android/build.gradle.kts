import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Ensure Android library modules have a namespace (fixes AGP 8+ requirement)
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension>("android") {
            // Some transitive Flutter plugins default to older compileSdk values,
            // which breaks aapt with newer AndroidX resources (e.g. lStar attr).
            val currentCompileSdk = compileSdk ?: 0
            if (currentCompileSdk < 36) {
                compileSdk = 36
            }
            if (namespace.isNullOrBlank()) {
                namespace = "com.example.${project.name}"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
