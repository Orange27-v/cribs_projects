<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use App\Mail\EmailVerificationMail;
use App\Mail\WelcomeMail;

class EmailVerificationController extends Controller
{
    /**
     * Verify email with code
     */
    public function verify(Request $request)
    {
        try {
            $request->validate([
                'email' => 'required|email',
                'code' => 'required|string|size:4',
            ]);

            $user = DB::table('cribs_users')
                ->where('email', $request->email)
                ->first();

            if (!$user) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'User not found',
                ], 404);
            }

            // Check if already verified
            if ($user->email_verified == 1) {
                return response()->json([
                    'status' => 'success',
                    'message' => 'Email already verified',
                ], 200);
            }

            // Check if code matches
            if ($user->email_verification_code !== $request->code) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid verification code',
                ], 400);
            }

            // Check if code has expired
            if (now()->isAfter($user->email_verification_expires_at)) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Verification code has expired',
                ], 400);
            }

            // Mark email as verified
            DB::table('cribs_users')
                ->where('email', $request->email)
                ->update([
                    'email_verified' => 1,
                    'email_verification_code' => null,
                    'email_verification_expires_at' => null,
                    'updated_at' => now(),
                ]);

            // Send welcome email
            try {
                $userName = $user->first_name . ' ' . $user->last_name;
                Mail::to($request->email)->send(new WelcomeMail($userName));
                Log::info('Welcome email sent to: ' . $request->email);
            } catch (\Exception $e) {
                // Log error but don't fail the verification
                Log::error('Failed to send welcome email: ' . $e->getMessage());
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Email verified successfully',
            ], 200);

        } catch (\Exception $e) {
            Log::error('Email verification error: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred during verification. Please try again later.',
            ], 500);
        }
    }

    /**
     * Resend verification code
     */
    public function resend(Request $request)
    {
        try {
            $request->validate([
                'email' => 'required|email',
            ]);

            $user = DB::table('cribs_users')
                ->where('email', $request->email)
                ->first();

            if (!$user) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'User not found',
                ], 404);
            }

            // Check if already verified
            if ($user->email_verified == 1) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Email already verified',
                ], 400);
            }

            // Generate new verification code
            $verificationCode = str_pad(random_int(0, 9999), 4, '0', STR_PAD_LEFT);

            // Update user with new code
            DB::table('cribs_users')
                ->where('email', $request->email)
                ->update([
                    'email_verification_code' => $verificationCode,
                    'email_verification_expires_at' => now()->addMinutes(15),
                    'updated_at' => now(),
                ]);

            // Send verification email
            $userName = $user->first_name . ' ' . $user->last_name;
            Mail::to($request->email)->send(
                new EmailVerificationMail($userName, $verificationCode)
            );

            return response()->json([
                'status' => 'success',
                'message' => 'Verification code resent successfully',
            ], 200);

        } catch (\Exception $e) {
            Log::error('Resend verification error: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while resending the code. Please try again later.',
            ], 500);
        }
    }
}
