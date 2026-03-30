<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class ChangePasswordController extends Controller
{
    public function changePassword(Request $request)
    {
        try {
            $request->validate([
                'current_password' => 'required',
                'new_password' => 'required|min:8|confirmed',
            ]);

            $agent = $request->user();

            if (!Hash::check($request->current_password, $agent->password)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Current password does not match'
                ], 400);
            }

            $agent->password = Hash::make($request->new_password);
            $agent->save();

            return response()->json([
                'success' => true,
                'message' => 'Password changed successfully'
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to change password: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while changing your password. Please try again later.'
            ], 500);
        }
    }
}
