# Deployment & Testing Guide (cPanel & Mobile)

## 1. Backend Deployment (cPanel)
If you have already uploaded the updated `composer.json` and `composer.lock` to your server via cPanel, follow these steps to install the new `google/apiclient` package:

### The Composer Command
In your cPanel Terminal or SSH, navigate to your `backend` directory and run:
```bash
composer install --no-dev
```
*   **Why `install`?**: Since you uploaded the `.lock` file, `install` ensures the server installs the *exact* same version we used during development.
*   **Why `--no-dev`?**: This is a production best practice; it keeps the server light by skipping development-only tools.

### Post-Install Checklist
1.  **Clear Cache**: Run `php artisan config:cache` to ensure Laravel sees your new `.env` variables.
2.  **Permissions**: Ensure `storage/app/google-service-account.json` is present and readable.
3.  **Logs**: Check `storage/logs/laravel.log` if you encounter any `500` errors during verification.

---

## 2. Google Play Billing Testing

### The "At Least Once" Rule (Mandatory)
Before Google Play Billing will work on a real device, you **must upload at least one version** (AAB or APK) to the **Internal Testing Track** in the Play Console.

1.  **Register App**: Create the app in Google Play Console.
2.  **Upload Build**: Upload your build to the **Internal Testing Track**.
3.  **Activate Products**: Ensure `cribs_agent_basic`, `cribs_agent_standard`, and `cribs_agent_premium` are created as "Subscriptions" and set to **Active**.
4.  **Add License Testers**: Add your Google account email to *Setup -> License Testing* to avoid real charges.

### Testing on a Physical Device
1.  **USB Debugging**: Connect your phone and ensure USB debugging is on.
2.  **Flutter Run**: Run `flutter run` from your computer. 
3.  **Verification**: Tap a plan. A Google Play sheet should appear with a "Test Card" badge.
4.  **Backend Connectivity**: If testing locally, use **Ngrok** to expose your local server so the phone can reach the verification API.

---

## 3. Reference Files Checked
- `backend/app/Http/Controllers/Agent/GoogleBillingController.php`
- `backend/routes/agent.php`
- `backend/config/app.php`
- `backend/composer.json`
- `backend/storage/app/google-service-account.json`
- `cribs_agents/lib/services/plan_service.dart`
- `cribs_agents/lib/screens/plans/plans_screen.dart`
