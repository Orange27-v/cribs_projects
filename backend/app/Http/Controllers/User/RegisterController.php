<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;
use App\Mail\WelcomeMail;
use App\Mail\EmailVerificationMail;
use App\Models\DeviceToken;
use Mailtrap\Helper\ResponseHelper;
use Mailtrap\MailtrapClient;
use Mailtrap\Mime\MailtrapEmail;
use Symfony\Component\Mime\Address;

class RegisterController extends Controller
{
    /**
     * Handle a user registration request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function __invoke(Request $request)
    {
        try {
            $request->validate([
                'first_name' => 'required|string|max:255',
                'last_name' => 'required|string|max:255',
                'email' => 'required|email|max:255|unique:cribs_users,email',
                'phone' => 'nullable|string|max:255',
                'latitude' => 'nullable|numeric',
                'longitude' => 'nullable|numeric',
                'password' => [
                    'required',
                    'string',
                    'min:8',
                    'regex:/[a-z]/',      // must contain at least one lowercase letter
                    'regex:/[A-Z]/',      // must contain at least one uppercase letter
                    'regex:/[0-9]/',      // must contain at least one digit
                    'regex:/[@$!%*#?&]/', // must contain at least one special character
                ],
                'area' => 'nullable|string|max:255',
                'fcm_token' => 'nullable|string',
                'platform' => 'nullable|string|in:android,ios',
            ]);

            // Generate verification code
            $verificationCode = str_pad(random_int(0, 9999), 4, '0', STR_PAD_LEFT);

            $user = DB::table('cribs_users')->updateOrInsert(
                ['email' => $request->email],
                [
                    'user_id' => mt_rand(100000, 999999),
                    'first_name' => $request->first_name,
                    'last_name' => $request->last_name,
                    'phone' => $request->phone,
                    'password' => Hash::make($request->password),
                    'latitude' => $request->latitude,
                    'longitude' => $request->longitude,
                    'area' => $request->area,
                    'email_verified' => 0, // Not verified yet
                    'email_verification_code' => $verificationCode,
                    'email_verification_expires_at' => now()->addMinutes(15),
                    'login_status' => 0, // Set initial login status to 0
                    'last_login' => null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );

            // Re-fetch the user to get the ID (since updateOrInsert doesn't return the model)
            $newUser = DB::table('cribs_users')->where('email', $request->email)->first();

            // Handle FCM Token if provided
            if ($request->has('fcm_token') && $request->fcm_token && $newUser) {
                DeviceToken::updateOrCreate(
                    [
                        'tokenable_id' => $newUser->id,
                        'tokenable_type' => 'user',
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
                $userName = $request->first_name . ' ' . $request->last_name;

                // Load the email template manually since we are bypassing Laravel's Mailable system for direct SDK usage
                $emailHtml = view('emails.email-verification', [
                    'userName' => $userName,
                    'verificationCode' => $verificationCode,
                    'expiryMinutes' => 15
                ])->render();

                $email = (new MailtrapEmail())
                    ->from(new Address('hello@cribsarena.com', 'Cribs Arena'))
                    ->to(new Address($request->email, $userName))
                    ->subject('Verify Your Email - Cribs Arena')
                    ->category('Email Verification')
                    ->html($emailHtml);

                $response = MailtrapClient::initSendingEmails(
                    apiKey: '379315de1755dd013cd40eaa93a80876'
                )->send($email);

                \Illuminate\Support\Facades\Log::info('Verification email sent via Mailtrap SDK: ' . json_encode(ResponseHelper::toArray($response)));
            } catch (\Exception $e) {
                // Log email error but don't fail registration
                \Illuminate\Support\Facades\Log::error('Verification email failed: ' . $e->getMessage());
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Registration successful. Please check your email for verification code.',
                'email' => $request->email,
            ], 201);

        } catch (ValidationException $e) {
            return response()->json(['errors' => $e->errors()], 422);
        } catch (\Exception $e) {
            // Log the error for debugging
            \Illuminate\Support\Facades\Log::error('Registration Error: ' . $e->getMessage());
            return response()->json(['error' => 'An unexpected error occurred.'], 500);
        }
    }
}
