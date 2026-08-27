allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Plugin antigo compilando contra SDK antigo.
//
// `usage_stats` 1.3.1 declara um `compileSdk` anterior ao 31 e o build de
// release quebra em `verifyReleaseResources` com
// "resource android:attr/lStar not found" — `lStar` só existe a partir do
// Android 12 (API 31).
//
// Aqui todo subprojeto Android é subido para o mesmo nível do app. Precisa
// vir **antes** do `evaluationDependsOn(":app")` abaixo: aquele força a
// avaliação, e um `afterEvaluate` registrado depois chega tarde
// ("Cannot run Project.afterEvaluate when the project is already evaluated").
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            try {
                ext.javaClass
                    .getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                    .invoke(ext, 36)
            } catch (_: Exception) {
                // Extensão sem esse método: nada a fazer, e nada a quebrar.
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
