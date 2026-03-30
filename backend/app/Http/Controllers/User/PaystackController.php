<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PaystackController extends Controller
{
    public function initializeTransaction(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:1',
            'email' => 'required|email',
            'metadata' => 'sometimes|array',
        ]);

        $amount = $request->amount * 100; // Convert to kobo
        $email = $request->email;
        $reference = 'cribs_arena_' . \Illuminate\Support\Str::random(32); // Generate a secure, unique reference

        try {
            $response = Http::timeout(30)->withHeaders([
                'Authorization' => 'Bearer ' . env('PAYSTACK_SECRET_KEY'),
                'Content-Type' => 'application/json',
            ])->post('https://api.paystack.co/transaction/initialize', [
                        'email' => $email,
                        'amount' => $amount,
                        'reference' => $reference,
                        'currency' => 'NGN',
                        'metadata' => $request->metadata,
                    ]);

            if ($response->successful()) {
                return response()->json($response->json());
            } else {
                Log::error('Paystack Initialization Error: ' . $response->body());

                return response()->json([
                    'message' => 'Failed to initialize payment gateway. Please try again later.'
                ], $response->status());
            }
        } catch (\Exception $e) {
            Log::error('Paystack Initialization Exception: ' . $e->getMessage());

            return response()->json([
                'message' => 'An error occurred while initializing the payment gateway. Please try again later.'
            ], 500);
        }
    }

    /**
     * Verify a Paystack transaction.
     *
     * @param  string  $reference  The transaction reference from Paystack.
     * @return array|null The Paystack verification response data, or null if verification fails.
     */
    public function verifyTransaction(string $reference): ?array
    {
        try {
            $response = Http::timeout(30)->withHeaders([
                'Authorization' => 'Bearer ' . env('PAYSTACK_SECRET_KEY'),
            ])->get("https://api.paystack.co/transaction/verify/$reference");

            Log::info('Paystack Verification Response: ' . $response->body());
            if ($response->successful() && $response->json('data.status') === 'success') {
                return $response->json('data');
            } else {
                Log::error('Paystack Verification Error: ' . $response->body());

                return null;
            }
        } catch (\Exception $e) {
            Log::error('Paystack Verification Exception: ' . $e->getMessage());

            return null;
        }
    }
}
