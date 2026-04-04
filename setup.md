# Production Build Setup Guide (Flutter Android)

This document provides a step-by-step record of the actions taken to configure and generate signed **Android App Bundles (AAB)** for **Cribs Arena** and **Cribs Agents**.

---

## 🏗️ 1. Keystore Generation
A unique release keystore was generated for both projects to securely sign the applications for the Google Play Store.

### Commands Used:
```bash
# Generated for both /cribs_arena and /cribs_agents
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload -storepass [PASSWORD] -keypass [PASSWORD] \
  -dname "CN=Cribs Arena, OU=Dev, O=Cribs Arena, L=Lagos, ST=Lagos, C=NG"
```
*   **Keystore Location**: `android/app/upload-keystore.jks`
*   **Alias**: `upload`

---

## 🔑 2. Signing Properties Setup
To keep credentials secure and easily manageable, a `key.properties` file was created in the `android/` directory of each project.

**File Path**: `[Project Root]/android/key.properties`
**Contents**:
```properties
storePassword=CribsArena@2026
keyPassword=CribsArena@2026
keyAlias=upload
storeFile=upload-keystore.jks
```

---

## ⚙️ 3. Gradle Configuration (`build.gradle.kts`)
The Android build scripts were modified to automatically load the signing credentials during a release build.

### 💉 Code Injected:
```kotlin
import java.util.Properties
import java.io.FileInputStream

// 1. Load properties from key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // 2. Define signing configuration
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // 3. Apply the signing configuration
            signingConfig = signingConfigs.getByName("release")
            
            // 🛠️ BUILD FIX: Disable minification to avoid R8 library conflicts
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}
```

---

## 🛡️ 4. Resolving Build Blockers
During the build process, we encountered an **R8 Minification Failure**. This was resolved by explicitly disabling code shrinking in the `build.gradle.kts` file:
*   `isMinifyEnabled = false`
*   `isShrinkResources = false`

This ensures that all library references (Firebase, Pusher, etc.) remain intact without needing complex ProGuard rules.

---

## 🚀 5. Generation Commands
To build the final production bundles, the following sequence was executed in each project root:

1.  **Clean Cache**: `flutter clean`
2.  **Sync Dependencies**: `flutter pub get`
3.  **Build Bundle**: `flutter build appbundle --release`

### 📍 Final File Locations:
*   **Cribs Arena**: `cribs_arena/build/app/outputs/bundle/release/app-release.aab`
*   **Cribs Agents**: `cribs_agents/build/app/outputs/bundle/release/app-release.aab`
