# Implementation Plan: Google Play Billing for Subscriptions

This document outlines the transition of the **Cribs Agent** subscription system from Paystack to **Google Play Billing (In-App Purchases)** to comply with Google Play Store policies for digital features (property listings). The **Agent Wallet** will remain on **Paystack** for future-proofing.

---

## 🛠 Phase 1: Google Console & Cloud Setup (Configuration)
1. **Google Play Console:**
   - Create subscription products (e.g., `cribs_standard_monthly`, `cribs_premium_monthly`).
   - Match the Product IDs with the existing `agent_plans` in the database.
2. **Google Cloud Console:**
   - Create a **Service Account** with the "Google Play Developer" role.
   - Generate and download the **JSON Key File** (to be stored securely on the backend).
3. **Environment (.env):**
   - Add `GOOGLE_PAY_MODE=test` or `live`.
   - Add `GOOGLE_APPLICATION_CREDENTIALS` path to the JSON key.

## 🚀 Phase 2: Backend (Laravel) Implementation
1. **Dependencies:**
   - Install `composer require google/apiclient`.
2. **New Controller (`GoogleBillingController`):**
   - **Verification Loop:** Create an endpoint `POST /subscription/verify-google` that:
     - Receives `purchaseToken` and `productId` from the Flutter app.
     - Verifies the token via the `Google_Service_AndroidPublisher` API.
     - Maps the `productId` to our internal `plan_id`.
     - Marks previous subscriptions as `Expired` and creates a new `Active` entry in `paid_subscribers`.
3. **Webhooks:**
   - Setup Google **Real-time Developer Notifications (RTDN)** via Google Cloud Pub/Sub to handle cancellations and renewals automatically.

## 📱 Phase 3: Frontend (Flutter) Implementation
1. **Dependency:**
   - Add `in_app_purchase: ^3.1.5` (or latest) to `pubspec.yaml`.
2. **Service Update (`PlanService`):**
   - Add methods to initialize the `InAppPurchase` connection.
   - Load available `ProductDetails` from Google using matching IDs.
3. **UI Update (`PlansScreen` & `CheckoutSheet`):**
   - Replace the Paystack WebView trigger with a native Google Play bottom sheet trigger.
   - On `PurchaseStatus.purchased`, send the `purchaseToken` to the Laravel backend for final activation.

## 💰 Phase 4: Wallet & Future-Proofing
1. **Paystack Logic:**
   - Extract Paystack logic specifically for the **Agent Wallet** funding.
   - Ensure the wallet does not automatically deduct for subscriptions (handled by Google Billing instead).
2. **Database Integrity:**
   - Ensure the `paid_subscribers` table remains the single source of truth for both payment types (Legacy/Test vs Google).

---

## 🚦 Testing Strategy
- **Internal Testing:** Use the **License Testers** feature in Google Play Console to perform transactions without real costs.
- **Verification:** Ensure the `property_limit` is correctly applied in `AgentPropertyController` after a Google purchase.
- **Recovery:** Test "Restore Purchases" functionality for agents switching devices.
