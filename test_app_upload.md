# Production Release & AAB Build Reference

This document provides the necessary configuration and build specifications for deploying **Cribs Arena** and **Cribs Agents** to the Google Play Store.

## 1. Project Specifications

| App Name | Package Name (`applicationId`) | Directory Root |
| :--- | :--- | :--- |
| **Cribs Arena** | `com.cribsarena.cribsarena` | `/cribs_arena` |
| **Cribs Agents** | `com.cribsarena.cribsagent` | `/cribs_agents` |

### Critical Versioning Rules
*   **Version Code**: Must be incremented (integer) for every single upload.
*   **Version Name**: Semantic versioning (e.g., `1.0.2+3`) defined in `pubspec.yaml`.

---

## 2. Build Workflow & Commands

Standardized commands for generating production Android App Bundles (AAB).

### AAB Generation
Run these commands from the respective project root:
```bash
# Clean project state
flutter clean

# Synchronize dependencies
flutter pub get

# Generate Signed Production Bundle
flutter build appbundle
```

### Output Location
The resulting file is always located at:
`[Project Root]/build/app/outputs/bundle/release/app-release.aab`

---

## 3. Google Play Console Configuration

### Internal Testing Infrastructure
*   **Track**: `Testing > Internal testing`
*   **Tester Access**: Ensure the **"Dev Team"** email list is created and actively selected under the Testers tab.
*   **License Testing**: Required for $0.00 In-App Purchase (IAP) validation. Add tester Gmail addresses to the global "License testing" section in the Console dashboard to enable **Test Cards**.

### Device Synchronization
1.  Accept the invite via the **"Join on Android"** link provided in the Console.
2.  Install the Store version at least once to establish the "Internal Test" handshake.
3.  Subsequent local debugging via `flutter run` will inherit this test status, allowing for live billing verification.

---

## 4. Production App Signing Reference

Secure signing is mandatory for Play Store acceptance. Both projects should follow this standardized structure.

### Signing Assets
*   **Keystore File**: `android/app/upload-keystore.jks`
*   **Configuration**: `android/key.properties`

### `key.properties` Schema
```properties
storePassword=YOUR_STABLE_PASSWORD
keyPassword=YOUR_STABLE_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

### Gradle Signing Implementation
Ensure the following logic is implemented in `android/app/build.gradle.kts` (or `build.gradle`):

```gradle
// 1. Load properties
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // 2. Define Signing Configuration
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            // 3. Apply to Release Build
            signingConfig signingConfigs.release
        }
    }
}
```

---

## 5. Technical Documentation & Tutorials
*   **AAB Deployment**: Search: *"Flutter build appbundle and upload to play console"*
*   **IAP Validation**: Search: *"Flutter In-App Purchase License Testing guide"*


---

## 6. Last Successful Build Summary (2026-03-30)

### Actions Taken:
- **Signing Configuration**: Configured `key.properties` and `build.gradle.kts` for both projects.
- **Keystore Generation**: Generated new `upload-keystore.jks` files using the password `CribsArena@2026`.
- **R8/Minification Fix**: Explicitly disabled minification (`isMinifyEnabled = false`) to resolve compilation blockers.
- **Build Execution**: Successfully generated signed Production App Bundles (AAB) for both applications.

### Final AAB Locations:
- **Cribs Arena**: `cribs_arena/build/app/outputs/bundle/release/app-release.aab`
- **Cribs Agents**: `cribs_agents/build/app/outputs/bundle/release/app-release.aab`
