<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;

class LogoutController extends Controller
{
    /**
     * Handle a user logout request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function __invoke(Request $request)
    {
        try {
            $user = $request->user();

            if ($user) {
                // Revoke the token that was used to authenticate the current request
                $user->currentAccessToken()->delete();

                // Update the user's login status in the database
                $user->forceFill([
                    'login_status' => 0,
                    'last_logout' => now(),
                ])->save();
            }

            return response()->json(['message' => 'Successfully logged out'], 200);

        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Logout Error: '.$e->getMessage());
            return response()->json(['error'=> 'An unexpected error occurred during logout.'], 500);
        }
    }
}
