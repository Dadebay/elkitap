
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
    
    // Force all plugins to compile with SDK 36
    afterEvaluate {
        extensions.findByName("android")?.apply {
            val compileSdkVersion = javaClass.getMethod("getCompileSdkVersion")
            val currentSdk = compileSdkVersion.invoke(this) as? Int
            if (currentSdk != null && currentSdk < 36) {
                javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    .invoke(this, 36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
