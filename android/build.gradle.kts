buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Оставляем твои версии
        classpath("com.android.tools.build:gradle:8.1.1")
        classpath("com.google.gms:google-services:4.4.3")
    }
}

// Настройка путей сборки (твоя логика)
val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // --- ВОТ ЭТОТ БЛОК РЕШАЕТ ПРОБЛЕМУ NAMESPACE ---
    afterEvaluate {
        if (project.extensions.findByName("android") != null) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            if (android.namespace == null) {
                // Назначаем временный namespace на основе имени проекта
                android.namespace = "com.patch.${project.name.replace("-", ".")}"
            }
        }
    }
}

subprojects {
    // Безопасная настройка зависимости от :app
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}