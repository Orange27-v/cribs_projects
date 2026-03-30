# Action Steps: Production Deployment & Billing Integration

This checklist tracks the concrete tasks required to synchronize both **Cribs Arena** and **Cribs Agents** for production release and Google Play Billing integration.

## 🟢 1. Configuration & Assets
- [ ] **Generate Release Keystores**: Create `upload-keystore.jks` for both projects to ensure secure signing.
- [ ] **Setup `key.properties`**: Configure credentials for both `/cribs_arena` and `/cribs_agents`.
- [ ] **Google Play Console Handshake**: 
    - [ ] Create App entries for both package names.
    - [ ] Upload initial internal test bundles to activate the "Testers" and "Billing" APIs.
- [ ] **Service Account**: Download the Google Cloud JSON Key for backend verification.

## 🟡 2. Backend Implementation (Laravel)
- [ ] **Environment Setup**: Add Google Application Credentials to the production `.env`.
- [ ] **Google SDK Integration**: Install `google/apiclient`.
- [ ] **Verification Endpoint**: Complete `GoogleBillingController` logic to verify `purchaseTokens`.
- [ ] **Pub/Sub Webhooks**: Configure Real-time Developer Notifications for subscription lifecycle events.

## 🔵 3. Frontend Integration (Flutter)
- [ ] **`in_app_purchase` Setup**: Finalize dependency injection in `pubspec.yaml` for both apps.
- [ ] **Matching Logic**: Ensure Product IDs in the Console exactly match the `PlanService` constants.
- [ ] **Checkout Flow**: 
    - [ ] Update `CheckoutSheet` to trigger the Google Play bottom sheet.
    - [ ] Implement robust error handling for "Cancelled" or "Failed" purchases.
- [ ] **Restoration logic**: Add a "Restore Purchases" button for user convenience.

## 🔴 4. Build & Validation
- [ ] **Production Build**: Generate signed AABs for both apps using the refactored `test_app_upload.md` reference.
- [ ] **Internal Test Cycle**:
    - [ ] Distribute "Join on Android" links to the Dev Team.
    - [ ] Validate $0.00 "License Test" transactions on physical devices.
- [ ] **Database Audit**: Verify that the `paid_subscribers` table correctly updates after a successful Google purchase.
