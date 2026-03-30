<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use App\Helpers\ChatSyncHelper;

class UserController extends Controller
{
    public function index()
    {
        return response()->json(['message' => 'User API endpoint']);
    }

    public function register(Request $request)
    {
        $validatedData = $request->validate([
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:cribs_users',
            'phone' => 'nullable|string|max:255',
            'area' => 'nullable|string|max:255',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'password' => 'required|string|min:6',
        ]);

        $user = User::create([
            'user_id' => mt_rand(100000, 999999),
            'first_name' => $validatedData['first_name'],
            'last_name' => $validatedData['last_name'],
            'email' => $validatedData['email'],
            'phone' => $validatedData['phone'] ?? null,
            'area' => $validatedData['area'] ?? null,
            'latitude' => $validatedData['latitude'] ?? null,
            'longitude' => $validatedData['longitude'] ?? null,
            'password' => Hash::make($validatedData['password']),
        ]);

        $token = $user->createToken('auth_token', ['user'])->plainTextToken;

        return response()->json([
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => $user,
        ]);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Invalid login details'], 401);
        }

        $user->login_status = 1;
        $user->last_login = now();
        $user->save();

        $token = $user->createToken('auth_token', ['user'])->plainTextToken;

        return response()->json([
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => $user
        ]);
    }

    public function logout(Request $request)
    {
        $user = $request->user();
        $user->login_status = 0;
        $user->last_logout = now();
        $user->save();

        $user->tokens()->delete();

        return response()->json(['message' => 'Logged out successfully']);
    }

    public function profile(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => $request->user()
        ]);
    }

    public function checkEmail(Request $request)
    {
        $validatedData = $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $validatedData['email'])->first();

        if ($user) {
            return response()->json(['exists' => true]);
        } else {
            return response()->json(['exists' => false]);
        }
    }

    public function updateProfilePicture(Request $request)
    {
        $request->validate([
            'profile_picture' => 'required|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);

        $user = $request->user();

        if ($request->hasFile('profile_picture')) {
            $path = $request->file('profile_picture')->store('profile_pictures', 'public');
            $user->profile_picture_url = $path;
            $user->save();

            // Sync with ChatDB
            ChatSyncHelper::syncProfile("user_{$user->user_id}", null, $path);

            return response()->json(['profile_picture_url' => asset('storage/' . $path)]);
        }

        return response()->json(['message' => 'No image uploaded'], 400);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validatedData = $request->validate([
            'name' => 'sometimes|string|max:255',
            'phone' => 'sometimes|string|max:255',
            'location' => 'sometimes|string|max:255',
            'profile_picture' => 'sometimes|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);

        // The name field might come as 'name' but the database has 'first_name' and 'last_name'.
        // For simplicity, we'll split the name into two parts.
        if (isset($validatedData['name'])) {
            $nameParts = explode(' ', $validatedData['name'], 2);
            $user->first_name = $nameParts[0];
            $user->last_name = $nameParts[1] ?? '';
        }

        if (isset($validatedData['phone'])) {
            $user->phone = $validatedData['phone'];
        }

        if (isset($validatedData['location'])) {
            $user->area = $validatedData['location'];
        }

        if ($request->hasFile('profile_picture')) {
            $path = $request->file('profile_picture')->store('profile_pictures', 'public');
            $user->profile_picture_url = $path;
        }

        $user->save();

        // Sync with ChatDB
        ChatSyncHelper::syncProfile(
            "user_{$user->user_id}",
            "{$user->first_name} {$user->last_name}",
            $user->profile_picture_url
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Profile updated successfully',
            'user' => $user,
        ]);
    }

    public function updatePassword(Request $request)
    {
        $request->validate([
            'password' => 'required|string|min:6',
        ]);

        $user = $request->user();
        $user->password = \Illuminate\Support\Facades\Hash::make($request->password);
        $user->save();

        return response()->json([
            'status' => 'success',
            'message' => 'Password updated successfully in backend.',
        ]);
    }

    public function agreeToTerms(Request $request)
    {
        $request->validate([
            'version' => 'required|string|max:20',
        ]);

        $user = $request->user();
        $user->agreed_to_terms_version = $request->version;
        $user->save();

        return response()->json([
            'status' => 'success',
            'message' => 'User agreement recorded successfully.',
        ]);
    }

    /**
     * Update user location coordinates
     */
    public function updateLocation(Request $request)
    {
        try {
            $user = $request->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Validate request
            $validatedData = $request->validate([
                'latitude' => 'required|numeric|between:-90,90',
                'longitude' => 'required|numeric|between:-180,180',
            ]);

            // Update user coordinates
            $user->latitude = $validatedData['latitude'];
            $user->longitude = $validatedData['longitude'];
            $user->save();

            return response()->json([
                'success' => true,
                'message' => 'Location updated successfully',
                'data' => [
                    'latitude' => $user->latitude,
                    'longitude' => $user->longitude
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to update location: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating your location. Please try again later.'
            ], 500);
        }
    }
}
