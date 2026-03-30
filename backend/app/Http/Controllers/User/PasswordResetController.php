<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use App\Mail\PasswordResetMail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Validator;
use Mailtrap\Helper\ResponseHelper;
use Mailtrap\MailtrapClient;
use Mailtrap\Mime\MailtrapEmail;
use Symfony\Component\Mime\Address;

class PasswordResetController extends Controller
{
    /**
     * Send password reset code to user's email
     */
    public function sendResetCode(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            // Check if user exists
            $user = DB::table('cribs_users')
                ->where('email', $request->email)
                ->first();

            if (!$user) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'No account found with this email address.'
                ], 404);
            }

            // Generate 4-digit reset code
            $resetCode = str_pad(random_int(0, 9999), 4, '0', STR_PAD_LEFT);

            // Set expiry time (15 minutes from now)
            $expiresAt = now()->addMinutes(15);

            // Update user with reset code and expiry
            DB::table('cribs_users')
                ->where('email', $request->email)
                ->update([
                    'password_reset_token' => $resetCode,
                    'password_reset_token_expires_at' => $expiresAt,
                    'updated_at' => now(),
                ]);

            // Send email with reset code using Mailtrap SDK
            $userName = $user->first_name . ' ' . $user->last_name;

            // Load the email template manually since we are bypassing Laravel's Mailable system for direct SDK usage
            $emailHtml = view('emails.password-reset', [
                'userName' => $userName,
                'resetCode' => $resetCode,
                'expiryMinutes' => 15
            ])->render();

            $email = (new MailtrapEmail())
                ->from(new Address('hello@cribsarena.com', 'Cribs Arena'))
                ->to(new Address($request->email, $userName))
                ->subject('Password Reset Code - Cribs Arena')
                ->category('Password Reset')
                ->html($emailHtml);

            $response = MailtrapClient::initSendingEmails(
                apiKey: '379315de1755dd013cd40eaa93a80876'
            )->send($email);

            \Log::info('Password reset email sent via Mailtrap SDK: ' . json_encode(ResponseHelper::toArray($response)));

            return response()->json([
                'status' => 'success',
                'message' => 'Password reset code has been sent to your email.',
            ], 200);

        } catch (\Exception $e) {
            \Log::error('Password Reset Error: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while sending the reset code. Please try again.'
            ], 500);
        }
    }

    /**
     * Verify the reset code
     */
    public function verifyResetCode(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'code' => 'required|string|size:4',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $user = DB::table('cribs_users')
                ->where('email', $request->email)
                ->first();

            if (!$user) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid email address.'
                ], 404);
            }

            // Check if code matches
            if ($user->password_reset_token !== $request->code) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid verification code.'
                ], 400);
            }

            // Check if code has expired
            if (now()->greaterThan($user->password_reset_token_expires_at)) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Verification code has expired. Please request a new one.'
                ], 400);
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Verification code is valid.',
            ], 200);

        } catch (\Exception $e) {
            \Log::error('Code Verification Error: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred during verification. Please try again.'
            ], 500);
        }
    }

    /**
     * Reset password with verified code
     */
    public function resetPassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'code' => 'required|string|size:4',
            'password' => 'required|string|min:6|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $user = DB::table('cribs_users')
                ->where('email', $request->email)
                ->first();

            if (!$user) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid email address.'
                ], 404);
            }

            // Verify code again
            if ($user->password_reset_token !== $request->code) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid verification code.'
                ], 400);
            }

            // Check if code has expired
            if (now()->greaterThan($user->password_reset_token_expires_at)) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Verification code has expired. Please request a new one.'
                ], 400);
            }

            // Update password and clear reset token
            DB::table('cribs_users')
                ->where('email', $request->email)
                ->update([
                    'password' => Hash::make($request->password),
                    'password_reset_token' => null,
                    'password_reset_token_expires_at' => null,
                    'updated_at' => now(),
                ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Password has been reset successfully. You can now log in with your new password.',
            ], 200);

        } catch (\Exception $e) {
            \Log::error('Password Reset Error: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while resetting your password. Please try again.'
            ], 500);
        }
    }
}
