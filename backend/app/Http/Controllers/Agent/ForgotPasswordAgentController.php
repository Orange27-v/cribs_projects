<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Agent;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;
use Mailtrap\Helper\ResponseHelper;
use Mailtrap\MailtrapClient;
use Mailtrap\Mime\MailtrapEmail;
use Symfony\Component\Mime\Address;

class ForgotPasswordAgentController extends Controller
{
    public function sendResetLink(Request $request)
    {
        try {
            $request->validate(['email' => 'required|email']);

            $agent = Agent::where('email', $request->email)->first();

            if (!$agent) {
                return response()->json(['message' => 'Email not found.'], 404);
            }

            // Generate 4 digit OTP
            $token = str_pad(mt_rand(0, 9999), 4, '0', STR_PAD_LEFT);

            $agent->password_reset_token = $token;
            $agent->password_reset_token_expires_at = now()->addMinutes(15);
            $agent->save();

            try {
                $agentName = $agent->first_name . ' ' . $agent->last_name;

                // Load the email template manually since we are bypassing Laravel's Mailable system for direct SDK usage
                $emailHtml = view('emails.password-reset', [
                    'userName' => $agentName,
                    'resetCode' => $token,
                    'expiryMinutes' => 15
                ])->render();

                $email = (new MailtrapEmail())
                    ->from(new Address('hello@cribsarena.com', 'Cribs Arena'))
                    ->to(new Address($agent->email, $agentName))
                    ->subject('Password Reset Code - Cribs Arena')
                    ->category('Agent Password Reset')
                    ->html($emailHtml);

                $response = MailtrapClient::initSendingEmails(
                    apiKey: '379315de1755dd013cd40eaa93a80876'
                )->send($email);

                Log::info('Agent password reset email sent via Mailtrap SDK: ' . json_encode(ResponseHelper::toArray($response)));
            } catch (\Exception $e) {
                Log::error('Password reset email failed: ' . $e->getMessage());
                return response()->json(['message' => 'Failed to send reset email.'], 500);
            }

            return response()->json(['message' => 'Password reset code sent to your email.']);
        } catch (\Exception $e) {
            Log::error('Failed to initiate password reset: ' . $e->getMessage());
            return response()->json([
                'message' => 'An error occurred while processing your request. Please try again later.'
            ], 500);
        }
    }

    public function verifyResetToken(Request $request)
    {
        try {
            $request->validate([
                'email' => 'required|email',
                'token' => 'required|string|size:4'
            ]);

            $agent = Agent::where('email', $request->email)
                ->where('password_reset_token', $request->token)
                ->first();

            if (!$agent) {
                return response()->json(['message' => 'Invalid code.'], 400);
            }

            if ($agent->password_reset_token_expires_at < now()) {
                return response()->json(['message' => 'Code expired.'], 400);
            }

            return response()->json(['message' => 'Code verified.']);
        } catch (\Exception $e) {
            Log::error('Failed to verify reset token: ' . $e->getMessage());
            return response()->json([
                'message' => 'An error occurred while verifying the code.'
            ], 500);
        }
    }

    public function resetPassword(Request $request)
    {
        try {
            $request->validate([
                'email' => 'required|email',
                'token' => 'required|string',
                'password' => 'required|string|min:6'
            ]);

            $agent = Agent::where('email', $request->email)
                ->where('password_reset_token', $request->token)
                ->first();

            if (!$agent) {
                return response()->json(['message' => 'Invalid code.'], 400);
            }

            if ($agent->password_reset_token_expires_at < now()) {
                return response()->json(['message' => 'Code expired.'], 400);
            }

            $agent->password = Hash::make($request->password);
            $agent->password_reset_token = null;
            $agent->password_reset_token_expires_at = null;
            $agent->save();

            return response()->json(['message' => 'Password has been reset successfully.']);
        } catch (\Exception $e) {
            Log::error('Failed to reset password: ' . $e->getMessage());
            return response()->json([
                'message' => 'An error occurred while resetting your password.'
            ], 500);
        }
    }
}
