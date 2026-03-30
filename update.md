# Subscription & Payment Architecture Update

## 1. Google Play Billing (Subscriptions)
The `cribs_agent` app uses **Google Play Billing** exclusively for agent subscriptions (Starter, Standard, Premium). 

*   **Why**: Google Play Store policy requires all digital feature access (like property listing limits) to be handled via their native billing system. Failure to do so leads to app rejection.
*   **Pricing Alignment**: The Flutter app is now aligned with the Laravel backend to use the **"Starter"** plan name (previously "Basic") for the `cribs_agent_basic` product ID.

## 2. Agent Wallet (Paystack)
The **Agent Wallet** remains integrated via **Paystack**. 
*   **Purpose**: The wallet is for *optional* non-subscription features (e.g., boosting a specific property, premium analytics).
*   **Current State**: Agents can fund their wallets, but no automatic deductions are performed yet. This future-proofs the app for transactional features that aren't recurring subscriptions.

## 3. Configuration & Deployment
*   **Backend Verification**: The Laravel backend verifies Google receipts using the `Google\Client` with a Service Account JSON file (`storage/app/google-service-account.json`).
*   **Package Name**: The `.env` variable `ANDROID_PACKAGE_NAME` must match the Flutter `applicationId` exactly for verification to succeed.
*   **Environment Mode**: `GOOGLE_PAY_MODE=test` or `live` is used as a flag. Actual billing behavior (Real vs. Test) is controlled by the Google Play Store app and Console settings.

## 4. How to Test on a Real Device
Google Play Billing **cannot** be tested on an emulator without the Play Store, nor on a device that hasn't registered the app with Google.

### The "At Least Once" Rule (Mandatory)
Before you can test Google Play Billing, you **must upload at least one version** (AAB or APK) to the **Internal Testing Track** once. 

*   **Why?**: Without this upload, the Google Play Store doesn't "know" your app's Package Name, your Product IDs, or your signing certificate. 
*   **Ongoing Testing**: After that first upload, you don't need to keep uploading. You can just connect your physical device and use `flutter run`. Google will successfully recognize the app identity from the Package Name.

### Step-by-Step Testing:
1.  **Register App**: Create the app in Google Play Console and upload at least **one** build (`.aab` or `.apk`) to the **Internal Testing Track**.
2.  **Activate Products**: Create the Subscription Product IDs and ensure they are set to **"Active."**
3.  **Add License Testers**: Add your Google email to *Setup -> License Testing* in the Console.
4.  **Local Run**: Connect your phone and use `flutter run`. Google will recognize the package name and show a **"Test instrument, will not be charged"** badge.
5.  **Backend Proxy**: If your backend is local, use **Ngrok** to create a public URL so the phone can reach the verification API.
