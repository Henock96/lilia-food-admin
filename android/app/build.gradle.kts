import java.util.Properties
import java.io.FileInputStream
plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration

    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }
val hasKeystore = keystorePropertiesFile.exists() &&
    keystoreProperties["keyAlias"] != null &&
    keystoreProperties["storeFile"] != null

// Clé Google Maps — même mécanisme que `lilia-app` et `lilia_food_delivery`.
//
// Cette app lisait sa clé depuis `res/values/google_maps_key.xml`, un fichier
// de ressources **gitignoré et sans gabarit committé** : trois mécanismes
// différents pour un seul besoin, dont le plus fragile. Un poste neuf ne
// pouvait pas construire l'app et rien n'indiquait pourquoi.
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}
val mapsApiKey: String =
    (localProperties["MAPS_API_KEY"] as String?)
        ?: providers.environmentVariable("MAPS_API_KEY").orNull
        ?: "YOUR_GOOGLE_MAPS_API_KEY"

// Refuse de produire un binaire de release sans vraie clé : sans elle, la
// carte de supervision est grise et aucune erreur ne le signale.
gradle.taskGraph.whenReady {
    val buildingRelease = allTasks.any { task ->
        task.name.contains("Release") &&
            (task.name.startsWith("assemble") || task.name.startsWith("bundle"))
    }
    if (buildingRelease && mapsApiKey == "YOUR_GOOGLE_MAPS_API_KEY") {
        throw GradleException(
            "Clé Google Maps absente : ajoutez `MAPS_API_KEY=<clé>` dans " +
                "android/local.properties (fichier gitignoré), ou exportez " +
                "MAPS_API_KEY."
        )
    }

    // Même raisonnement pour la signature (ADM-18, audit du 13/10/2026) : on
    // casse au moment de fabriquer le binaire, pas au moment de configurer le
    // projet. L'ancien repli signait la release avec la clé de debug, publique,
    // sur un simple avertissement que personne ne lit dans un log Gradle.
    if (buildingRelease && !hasKeystore) {
        throw GradleException(
            "Trousseau de signature absent : créez `android/key.properties` " +
                "(fichier gitignoré) avec keyAlias, keyPassword, storeFile et " +
                "storePassword. Sans lui, la release serait signée avec la clé " +
                "de debug et refusée par le Play Store."
        )
    }
}

android {
    namespace = "com.dreesis.lilia_admin"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    lint {
        abortOnError = false
        checkReleaseBuilds = false
    }
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.dreesis.lilia_admin"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        multiDexEnabled = true
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Injecte la clé Maps dans AndroidManifest (${MAPS_API_KEY}).
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }
    // Signature release (audit 2026-08-01, M-6). Le bloc était commenté : l'AAB
    // produit était signé avec la clé de DEBUG — inpubliable sur le Play Store,
    // et n'importe qui peut produire une mise à jour acceptée par les appareils
    // (la clé de debug Android est publique).
    //
    // `android/key.properties` est gitignoré et absent des machines de dev qui
    // ne publient pas : on ne déclare la config que s'il est présent, sinon
    // toute tâche, `flutter run` en debug compris, échouerait au chargement du
    // Gradle. Sans trousseau, la garde `whenReady` ci-dessus refuse la release.
    signingConfigs {
        if (hasKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
    buildTypes {
        release {
            // Plus aucun repli sur la clé de debug.
            if (hasKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("com.google.android.material:material:1.13.0")

    // Edge-to-edge support for Android 15+
    implementation("androidx.activity:activity-ktx:1.9.3")

    // Firebase dependencies
    implementation(platform("com.google.firebase:firebase-bom:34.18.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
}
flutter {
    source = "../.."
}
