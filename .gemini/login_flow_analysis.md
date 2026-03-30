# Login Flow & SharedPreferences State Management

## Complete Analysis of User Authentication Flow
**Date:** 2025-12-21  
**Starting Point:** `splash_screen.dart`

---

## 🔄 Complete Login Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     APP STARTUP                              │
│                  (splash_screen.dart)                        │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Check SharedPreferences for:                            │
│     • 'onboarded_user' (bool)                               │
│     • 'auth_token' (string) via AuthService                 │
└─────────────────────────────────────────────────────────────┘
                           │
                ┌──────────┴──────────┐
                │                     │
                ▼                     ▼
        ┌──────────────┐      ┌──────────────┐
        │ Token Found? │      │  No Token    │
        │     YES      │      │     NO       │
        └──────────────┘      └──────────────┘
                │                     │
                ▼                     ▼
┌─────────────────────────┐   ┌──────────────────────┐
│ 2. Validate Token:      │   │ Check Onboarding:    │
│    • Fetch user data    │   │  • onboarded_user?   │
│    • Fetch payment keys │   └──────────────────────┘
│    • Timeout: 5-6 sec   │            │
└─────────────────────────┘            │
                │              ┌───────┴────────┐
        ┌───────┴────────┐    │                │
        │                │    ▼                ▼
        ▼                ▼   TRUE            FALSE
    ✅ Valid        ❌ Invalid  │                │
        │                │    │                │
        │                │    ▼                ▼
        │                │  Login         Onboarding
        │                │  Screen         Screen
        │                │
        │                ▼
        │         ┌──────────────┐
        │         │ Clear Token  │
        │         │ → LoginScreen│
        │         └──────────────┘
        │
        ▼
┌─────────────────────────┐
│ 3. Load User Data:      │
│    • Set UserProvider   │
│    • Set Payment Keys   │
│    • Send FCM Token     │
└─────────────────────────┘
        │
        ▼
┌─────────────────────────┐
│ 4. Navigate Based On:   │
│    • onboarded_user?    │
└─────────────────────────┘
        │
    ┌───┴────┐
    │        │
    ▼        ▼
  TRUE     FALSE
    │        │
    ▼        ▼
MainLayout  PermitNotification
  (Home)      Screen
```

---

## 📱 SharedPreferences Storage

### Keys Used:

| Key | Type | Purpose | Set By | Read By |
|-----|------|---------|--------|---------|
| `'auth_token'` | String | JWT authentication token | `UserLoginService` | `AuthService.getToken()` |
| `'onboarded_user'` | Bool | Has user completed onboarding? | Onboarding flow | `SplashScreen` |

---

## 🔐 Token Management Flow

### 1. **Login Process** (`login_screen.dart` → `user_login_service.dart`)

```dart
// Step 1: User enters credentials
final email = _emailPhoneController.text.trim();
final password = _passwordController.text;

// Step 2: Call backend login API
var loginResponse = await authService.loginService
    .login(email: email, password: password);

// Step 3: In UserLoginService.login():
if (response.statusCode >= 200 && response.statusCode < 300) {
  final Map<String, dynamic> responseData = json.decode(response.body);
  final String? token = responseData['token'];
  
  if (token != null && token.isNotEmpty) {
    // ✅ SAVE TOKEN TO SHAREDPREFERENCES
    await _authService.saveToken(token);
  }
}
```

### 2. **Token Storage** (`auth_service.dart`)

```dart
class AuthService {
  static const String _authTokenKey = 'auth_token';

  // Save token to SharedPreferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);  // ← STORED HERE
  }

  // Retrieve token from SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);  // ← RETRIEVED HERE
  }

  // Clear token (logout)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);  // ← DELETED HERE
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
```

---

## 🚀 Splash Screen Logic (`splash_screen.dart`)

### Complete Flow:

```dart
void _checkOnboardingStatus() async {
  // 1️⃣ Get SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding = prefs.getBool('onboarded_user') ?? false;
  
  // 2️⃣ Get saved token
  final String? authToken = await UserAuthService().getToken();
  
  // 3️⃣ Decision Tree
  if (authToken != null) {
    // TOKEN EXISTS - Try auto-login
    try {
      // Validate token by fetching user data
      final userData = await authService.fetchUserData()
          .timeout(const Duration(seconds: 5));
      
      // Fetch payment keys
      final paymentKeys = await paymentService.getPaymentKeys()
          .timeout(const Duration(seconds: 5));
      
      // ✅ TOKEN VALID - Set user data
      userProvider.setUser(userData['user']);
      userProvider.setPaymentKeys(publicKey, '');
      
      // Send FCM token (non-blocking)
      await firebaseMessagingService.sendPendingFCMToken(authToken);
      
      // Navigate based on onboarding status
      if (hasCompletedOnboarding) {
        Navigator.pushReplacement(context, 
          MaterialPageRoute(builder: (context) => const MainLayout()));
      } else {
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const PermitNotificationScreen()));
      }
      
    } catch (e) {
      // ❌ TOKEN INVALID - Clear and go to login
      await UserAuthService().logout();  // Clears token
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
    
  } else {
    // NO TOKEN - User not logged in
    if (hasCompletedOnboarding) {
      // Onboarded but logged out → Login
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const LoginScreen()));
    } else {
      // New user → Onboarding
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()));
    }
  }
}
```

---

## 🔄 Auto-Login Mechanism

### How It Works:

1. **App Starts** → Splash screen shows
2. **Check Token** → `AuthService.getToken()` reads from SharedPreferences
3. **Token Found?**
   - **YES** → Validate with backend (`fetchUserData()`)
     - **Valid** → Load user data → Navigate to MainLayout/PermitNotification
     - **Invalid** → Clear token → Navigate to LoginScreen
   - **NO** → Check onboarding status
     - **Onboarded** → Navigate to LoginScreen
     - **Not Onboarded** → Navigate to OnboardingScreen

### Timeout Protection:

```dart
// ✅ 5-second timeout per request
await authService.fetchUserData().timeout(const Duration(seconds: 5))

// ✅ 6-second overall timeout
await Future.wait([...]).timeout(
  const Duration(seconds: 6),
  onTimeout: () {
    throw TimeoutException('Overall request timeout');
  },
);
```

**Why?** Prevents app from hanging on slow/failed network requests.

---

## 🔒 Logout Flow

### Process:

```dart
Future<void> logout() async {
  final String? token = await getToken();
  
  // 1️⃣ Call backend logout endpoint
  if (token != null) {
    await http.post(
      Uri.parse("$kUserBaseUrl/logout"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }
  
  // 2️⃣ Clear local token from SharedPreferences
  await clearToken();  // ← Removes 'auth_token' key
  
  // 3️⃣ Clear FCM token
  await FirebaseMessagingService.clearFCMToken();
}
```

---

## 📊 State Persistence Summary

### What Gets Saved:

| Data | Storage | When Saved | When Cleared |
|------|---------|------------|--------------|
| **Auth Token** | SharedPreferences (`'auth_token'`) | After successful login | On logout or token invalid |
| **Onboarding Status** | SharedPreferences (`'onboarded_user'`) | After completing onboarding | Never (persists) |
| **User Data** | UserProvider (in-memory) | After token validation | On app restart or logout |
| **Payment Keys** | UserProvider (in-memory) | After token validation | On app restart or logout |

### Persistence Behavior:

- ✅ **Auth Token** - Persists across app restarts (auto-login)
- ✅ **Onboarding Status** - Persists forever (never shown again)
- ❌ **User Data** - Lost on app restart (re-fetched from backend)
- ❌ **Payment Keys** - Lost on app restart (re-fetched from backend)

---

## 🎯 Key Design Decisions

### 1. **Token-Based Authentication**
- JWT token stored in SharedPreferences
- Token sent with every API request in `Authorization` header
- Token validated on app startup

### 2. **Auto-Login**
- If token exists → Try to validate
- If validation succeeds → Auto-login
- If validation fails → Force re-login

### 3. **Onboarding Separation**
- Onboarding status separate from auth status
- Logged-in user can still need onboarding
- Onboarded user can be logged out

### 4. **Timeout Protection**
- 5-second timeout per API call
- 6-second overall timeout
- Prevents indefinite loading

### 5. **Error Handling**
- Token invalid → Clear and go to login
- Network error → Clear and go to login
- Critical error → Fallback to onboarding/login

---

## 🔍 Security Considerations

### ✅ Good Practices:

1. **Token in SharedPreferences** - Secure on device
2. **Token Validation** - Checked on every app start
3. **Automatic Logout** - On token expiry
4. **Backend Logout** - Invalidates token server-side
5. **No Password Storage** - Only token is stored

### ⚠️ Potential Improvements:

1. **Encrypted Storage** - Consider `flutter_secure_storage` for token
2. **Token Refresh** - Implement refresh token mechanism
3. **Biometric Auth** - Add fingerprint/face ID option
4. **Session Timeout** - Auto-logout after inactivity

---

## 📝 Code Flow Summary

### Login → Storage:
```
LoginScreen 
  → UserLoginService.login() 
  → Backend API 
  → Response with token 
  → AuthService.saveToken() 
  → SharedPreferences.setString('auth_token', token)
```

### App Start → Validation:
```
SplashScreen 
  → AuthService.getToken() 
  → SharedPreferences.getString('auth_token') 
  → UserAuthService.fetchUserData() 
  → Backend validates token 
  → Navigate to MainLayout/Login
```

### Logout → Clear:
```
LogoutButton 
  → UserAuthService.logout() 
  → Backend logout API 
  → AuthService.clearToken() 
  → SharedPreferences.remove('auth_token') 
  → Navigate to LoginScreen
```

---

## 🎉 Conclusion

The login flow is well-structured with:

✅ **Persistent Authentication** - Token saved in SharedPreferences  
✅ **Auto-Login** - Validates token on app start  
✅ **Proper Logout** - Clears both local and server-side sessions  
✅ **Error Handling** - Graceful fallbacks for network/auth failures  
✅ **Timeout Protection** - Prevents indefinite loading  
✅ **Separation of Concerns** - Auth and onboarding are independent  

**The system provides a smooth, secure user experience with persistent login state! 🚀**
