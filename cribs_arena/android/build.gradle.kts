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

    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-Xlint:none")
    }

    if (project.name == "flutter_paystack") {
        val configureNamespace = {
            project.extensions.configure<com.android.build.gradle.LibraryExtension> {
                namespace = "com.arttitude360.flutter_paystack"
            }
        }
        if (project.state.executed) {
            configureNamespace()
        } else {
            project.afterEvaluate {
                configureNamespace()
            }
        }
    }

    if (project.name == "pusher_client") {
        val configurePusherClient = {
            project.extensions.configure<com.android.build.gradle.LibraryExtension> {
                namespace = "com.github.chinloyal.pusher_client"
                compileSdk = 33
                defaultConfig {
                    minSdk = 21
                }
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_11
                    targetCompatibility = JavaVersion.VERSION_11
                }
            }
        }
        if (project.state.executed) {
            configurePusherClient()
        } else {
            project.afterEvaluate {
                configurePusherClient()
            }
        }
        project.tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            kotlinOptions {
                jvmTarget = "11"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
