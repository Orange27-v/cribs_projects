<?php

namespace App\Http\Controllers\Verification;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Verification;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class UserVerificationStatusController extends Controller
{
    /**
     * Get the current user's verification status for a specific type
     * 
     * @param Request $request
     * @param string $type (nin, bvn, vnin)
     * @return \Illuminate\Http\JsonResponse
     */
    public function getUserVerificationStatus(Request $request, $type)
    {
        try {
            $user = Auth::user();
            $receiverType = $user instanceof \App\Models\Agent ? 'agent' : 'user';

            // Validate type
            if (!in_array($type, ['nin', 'bvn', 'vnin'])) {
                return response()->json([
                    'error' => 'Invalid verification type. Must be nin, bvn, or vnin.'
                ], 400);
            }

            // Get the latest verification for this user and type
            $verification = Verification::where('receiver_id', $user->id)
                ->where('receiver_type', $receiverType)
                ->where('type', $type)
                ->latest()
                ->first();

            if (!$verification) {
                return response()->json([
                    'has_verification' => false,
                    'message' => 'No verification found for this type.'
                ]);
            }

            // Only report has_verification: true for pending or verified
            // This allows the frontend to show the form again if it failed
            $hasVerification = in_array($verification->status, ['pending', 'verified']);

            return response()->json([
                'has_verification' => $hasVerification,
                'verification_id' => $verification->verification_id,
                'type' => $verification->type,
                'status' => $verification->status,
                'value' => $verification->value,
                'qoreid_reference' => $verification->qoreid_reference,
                'response_payload' => $verification->response_payload,
                'created_at' => $verification->created_at,
                'updated_at' => $verification->updated_at,
                'message' => $this->getStatusMessage($verification),
            ]);
        } catch (\Exception $e) {
            Log::error('User verification status check failed: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while checking your verification status. Please try again later.'
            ], 500);
        }
    }

    /**
     * Get a user-friendly status message based on verification status
     */
    private function getStatusMessage($verification): string
    {
        $type = strtoupper($verification->type);

        switch ($verification->status) {
            case 'verified':
                return "{$type} verification successful! Your identity has been verified.";
            case 'failed':
                $errorMessage = '';
                if ($verification->response_payload && isset($verification->response_payload['error'])) {
                    $errorMessage = $verification->response_payload['error'];
                }
                return "{$type} verification failed. " . ($errorMessage ?: 'Please check your details and try again.');
            case 'pending':
            default:
                return "{$type} verification is being processed. Please wait...";
        }
    }
}
