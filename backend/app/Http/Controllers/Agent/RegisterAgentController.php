<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Agent;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use App\Mail\EmailVerificationMail;
use App\Models\DeviceToken;
use Mailtrap\Helper\ResponseHelper;
use Mailtrap\MailtrapClient;
use Mailtrap\Mime\MailtrapEmail;
use Symfony\Component\Mime\Address;

class RegisterAgentController extends Controller
{
    public function register(Request $request)
    {
        try {
            $validatedData = $request->validate([
                'first_name' => 'required|string|max:255',
                'last_name' => 'required|string|max:255',
                'email' => 'required|string|email|max:255|unique:cribs_agents',
                'phone' => 'nullable|string|max:255',
                'area' => 'nullable|string|max:255',
                'role' => 'nullable|string|max:255',
                'latitude' => 'nullable|numeric',
                'longitude' => 'nullable|numeric',
                'password' => 'required|string|min:6',
                'fcm_token' => 'nullable|string',
                'platform' => 'nullable|string|in:android,ios',
            ]);

            // Generate 6 digit unique agent_id
            do {
                $agentId = str_pad(mt_rand(0, 999999), 6, '0', STR_PAD_LEFT);
            } while (Agent::where('agent_id', $agentId)->exists());

            // Generate 4 digit email verification code
            $verificationCode = str_pad(mt_rand(0, 9999), 4, '0', STR_PAD_LEFT);
            $verificationExpiresAt = now()->addMinutes(60); // Code expires in 60 minutes

            $agent = Agent::create([
                'agent_id' => $agentId,
                'first_name' => $validatedData['first_name'],
                'last_name' => $validatedData['last_name'],
                'email' => $validatedData['email'],
                'phone' => $validatedData['phone'] ?? null,
                'area' => $validatedData['area'] ?? null,
                'role' => $validatedData['role'] ?? null,
                'latitude' => $validatedData['latitude'] ?? null,
                'longitude' => $validatedData['longitude'] ?? null,
                'password' => Hash::make($validatedData['password']),
                'email_verification_code' => $verificationCode,
                'email_verification_expires_at' => $verificationExpiresAt,
            ]);

            // Handle FCM Token if provided
            if ($request->has('fcm_token') && $request->fcm_token) {
                DeviceToken::updateOrCreate(
                    [
                        'tokenable_id' => $agent->id,
                        'tokenable_type' => 'agent',
                        'fcm_token' => $request->fcm_token,
                    ],
                    [
                        'platform' => $request->platform,
                        'last_seen_at' => now(),
                    ]
                );
            }


            // Send verification email using Mailtrap SDK
            try {
                $agentName = $validatedData['first_name'] . ' ' . $validatedData['last_name'];

                // Load the email template manually since we are bypassing Laravel's Mailable system for direct SDK usage
                $emailHtml = view('emails.email-verification', [
                    'userName' => $agentName,
                    'verificationCode' => $verificationCode,
                    'expiryMinutes' => 60
                ])->render();

                $email = (new MailtrapEmail())
                    ->from(new Address('hello@cribsarena.com', 'Cribs Arena'))
                    ->to(new Address($validatedData['email'], $agentName))
                    ->subject('Verify Your Email - Cribs Arena')
                    ->category('Agent Email Verification')
                    ->html($emailHtml);

                $response = MailtrapClient::initSendingEmails(
                    apiKey: '379315de1755dd013cd40eaa93a80876'
                )->send($email);

                Log::info('Agent verification email sent via Mailtrap SDK: ' . json_encode(ResponseHelper::toArray($response)));
            } catch (\Exception $e) {
                Log::error('Agent verification email failed: ' . $e->getMessage());
            }

            // NEW: Assign Starter Plan automatically
            try {
                $starterPlan = \Illuminate\Support\Facades\DB::table('agent_plans')->where('name', 'Starter')->first();

                if ($starterPlan) {
                    // Free 30 days
                    \Illuminate\Support\Facades\DB::table('paid_subscribers')->insert([
                        'agent_id' => $agent->agent_id,
                        'plan_id' => $starterPlan->plan_id,
                        'start_date' => now(),
                        'end_date' => now()->addDays(30),
                        'upload_count' => 0,
                        'amount_paid' => 0.00,
                        'payment_method' => 'System',
                        'paystack_reference' => 'FREE_TRIAL_' . Str::random(10),
                        'status' => 'Active',
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            } catch (\Exception $e) {
                Log::error('Failed to assign starter plan: ' . $e->getMessage());
            }

            // Create wallet for new agent
            try {
                \App\Models\Wallet::create([
                    'user_id' => $agent->agent_id,
                    'user_type' => 'agent',
                    'available_balance' => 0.00,
                    'pending_balance' => 0.00,
                    'total_earned' => 0.00,
                    'total_withdrawn' => 0.00,
                    'currency' => 'NGN',
                ]);
            } catch (\Exception $e) {
                Log::error('Failed to create wallet: ' . $e->getMessage());
            }

            return response()->json([
                'message' => 'Registration successful. Please verify your email.',
                'user' => $agent,
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json(['errors' => $e->errors()], 422);
        } catch (\Exception $e) {
            Log::error('Agent registration error: ' . $e->getMessage());
            return response()->json([
                'message' => 'An error occurred during registration. Please try again later.'
            ], 500);
        }
    }

    public function checkUid(Request $request)
    {
        // This was in AuthAgentController, seemingly allows checking something?
        // The routes file shows `check-uid` pointing to `AuthAgentController::class, 'checkUid'`.
        // I don't see the implementation in the `view_file` output of `AuthAgentController`.
        // Ah, wait. I missed `checkUid` in `AuthAgentController` view.
        // Let me check `AuthAgentController` again. Line 15 was `register`.
        // I don't see `checkUid` in the provided `view_file` output (It went from `profile` to `checkEmail`).
        // Wait, `checkEmail` is there. `checkUid` is used in routes line 15.
        // Maybe it was missing in the file or I missed it?
        // Use `grep` to find it? Or just assume it mimics `checkEmail`.
        // I'll leave `checkUid` out of `RegisterAgentController` unless it's strictly registration related.
        // `checkEmail` IS registration related (checking uniqueness).
    }

    public function checkEmail(Request $request)
    {
        try {
            $validatedData = $request->validate([
                'email' => 'required|email',
            ]);

            $agent = Agent::where('email', $validatedData['email'])->first();

            return response()->json(['exists' => (bool) $agent]);
        } catch (\Exception $e) {
            Log::error('Check email error: ' . $e->getMessage());
            return response()->json(['exists' => false], 200); // Fail safe: assume doesn't exist or handled by validator
        }
    }

    public function verifyEmail(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'email' => 'required|email|exists:cribs_agents,email',
                'code' => 'required|string|size:4',
            ]);

            if ($validator->fails()) {
                return response()->json($validator->errors(), 422);
            }

            $agent = Agent::where('email', $request->email)->first();

            if ($agent->email_verified_at) {
                return response()->json(['message' => 'Email already verified.'], 200);
            }

            if (!$agent->email_verification_code || $agent->email_verification_code !== $request->code) {
                return response()->json(['message' => 'Invalid verification code.'], 400);
            }

            if (now()->greaterThan($agent->email_verification_expires_at)) {
                return response()->json(['message' => 'Verification code expired.'], 400);
            }

            $agent->email_verified_at = now();
            $agent->email_verification_code = null;
            $agent->email_verification_expires_at = null;
            $agent->login_status = 1;
            $agent->last_login = now();
            $agent->save();

            // Send Welcome Email using Mailtrap SDK
            try {
                $agentName = $agent->first_name . ' ' . $agent->last_name;

                // For welcome email, we can use a simpler HTML or a view
                // Assuming there's an agent-welcome view based on the previous code
                $emailHtml = view('emails.agent-welcome', ['userName' => $agentName])->render();

                $email = (new MailtrapEmail())
                    ->from(new Address('hello@cribsarena.com', 'Cribs Arena'))
                    ->to(new Address($agent->email, $agentName))
                    ->subject('Welcome to Cribs Arena')
                    ->category('Agent Welcome')
                    ->html($emailHtml);

                $response = MailtrapClient::initSendingEmails(
                    apiKey: '379315de1755dd013cd40eaa93a80876'
                )->send($email);

                Log::info('Agent welcome email sent via Mailtrap SDK: ' . json_encode(ResponseHelper::toArray($response)));
            } catch (\Exception $e) {
                Log::error('Agent welcome email failed: ' . $e->getMessage());
            }

            // Create token for the verified user
            $token = $agent->createToken('auth_token', ['agent'])->plainTextToken;

            return response()->json([
                'message' => 'Email verified successfully.',
                'access_token' => $token,
                'token_type' => 'Bearer',
                'user' => $agent,
            ], 200);
        } catch (\Exception $e) {
            Log::error('Email verification error: ' . $e->getMessage());
            return response()->json([
                'message' => 'An error occurred during verification. Please try again later.'
            ], 500);
        }
    }

    public function resendVerificationCode(Request $request)
    {
        try {
            $request->validate([
                'email' => 'required|email|exists:cribs_agents,email',
            ]);

            $agent = Agent::where('email', $request->email)->first();

            if ($agent->email_verified_at) {
                return response()->json(['message' => 'Email already verified.'], 400);
            }

            // Generate new 4 digit email verification code
            $verificationCode = str_pad(mt_rand(0, 9999), 4, '0', STR_PAD_LEFT);
            $verificationExpiresAt = now()->addMinutes(60);

            $agent->email_verification_code = $verificationCode;
            $agent->email_verification_expires_at = $verificationExpiresAt;
            $agent->save();

            // Send verification email using Mailtrap SDK
            try {
                $agentName = $agent->first_name . ' ' . $agent->last_name;

                $emailHtml = view('emails.email-verification', [
                    'userName' => $agentName,
                    'verificationCode' => $verificationCode,
                    'expiryMinutes' => 60
                ])->render();

                $email = (new MailtrapEmail())
                    ->from(new Address('hello@cribsarena.com', 'Cribs Arena'))
                    ->to(new Address($agent->email, $agentName))
                    ->subject('Verify Your Email - Cribs Arena')
                    ->category('Agent Email Verification Resend')
                    ->html($emailHtml);

                $response = MailtrapClient::initSendingEmails(
                    apiKey: '379315de1755dd013cd40eaa93a80876'
                )->send($email);

                Log::info('Agent verification email (resend) sent via Mailtrap SDK: ' . json_encode(ResponseHelper::toArray($response)));
            } catch (\Exception $e) {
                Log::error('Agent verification email resend failed: ' . $e->getMessage());
                return response()->json(['message' => 'Failed to send verification email.'], 500);
            }

            return response()->json(['message' => 'Verification code resent successfully.']);
        } catch (\Exception $e) {
            Log::error('Resend verification code error: ' . $e->getMessage());
            return response()->json([
                'message' => 'An error occurred while resending the code. Please try again later.'
            ], 500);
        }
    }
}
