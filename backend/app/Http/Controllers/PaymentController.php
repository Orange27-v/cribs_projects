<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    public function getPaymentKeys()
    {
        try {
            // SECURITY: Only send public key to client
            // Secret key must NEVER be exposed to client-side code
            // Backend uses secret key for transaction initialization and verification
            return response()->json([
                'publicKey' => config('services.paystack.public_key'),
                // secretKey intentionally NOT sent to client for security
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to get payment keys: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while loading payment configuration.'
            ], 500);
        }
    }
}
