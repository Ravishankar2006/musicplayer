allprojects {
    repositories {
        google()
        mavenCentral()
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

subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val task = this
        try {
            val compilerOptions = task.javaClass.getMethod("getCompilerOptions").invoke(task)
            val jvmTarget = compilerOptions.javaClass.getMethod("getJvmTarget").invoke(compilerOptions)
            jvmTarget.javaClass.getMethod("set", org.jetbrains.kotlin.gradle.dsl.JvmTarget::class.java).invoke(jvmTarget, org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        } catch (e: Exception) {
            try {
                val kotlinOptions = task.javaClass.getMethod("getKotlinOptions").invoke(task)
                kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java).invoke(kotlinOptions, "11")
            } catch (e2: Exception) {}
        }
    }
    
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "11"
        targetCompatibility = "11"
    }

    // Configure Android projects
    listOf("com.android.application", "com.android.library").forEach { pluginId ->
        plugins.withId(pluginId) {
            val android = extensions.getByName("android")
            
            // Force compileSdk to 36
            try {
                android.javaClass.getMethod("setCompileSdk", Int::class.java).invoke(android, 36)
            } catch (e1: Exception) {
                try {
                    android.javaClass.getMethod("setCompileSdkVersion", Object::class.java).invoke(android, "android-36")
                } catch (e2: Exception) {}
            }

            // Fix namespaces
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                if (getNamespace.invoke(android) == null) {
                    setNamespace.invoke(android, project.group.toString())
                }
            } catch (e: Exception) {}
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
