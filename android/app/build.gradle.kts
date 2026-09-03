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
    // ne publient pas : on ne déclare la config que s'il est présent, sinon un
    // simple `flutter run --release` local échouerait au chargement du Gradle.
    signingConfigs {
        if (keystorePropertiesFile.exists()) {
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
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "⚠️  android/key.properties absent — build release signé avec la clé de DEBUG. " +
                    "NE PAS PUBLIER cet artefact."
                )
                signingConfigs.getByName("debug")
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
