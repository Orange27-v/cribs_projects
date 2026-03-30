<?php

namespace App\Http\Controllers\Verification;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Verification;
use App\Services\VerificationService; // Import the service
use Illuminate\Support\Facades\Log;

class VerificationStatusController extends Controller
{
    protected $verificationService;

    public function __construct(VerificationService $verificationService)
    {
        $this->verificationService = $verificationService;
    }

    public function status(Request $request, $verification_id)
    {
        try {
            $verification = Verification::where('verification_id', $verification_id)->firstOrFail();

            // Return comprehensive verification status
            return response()->json([
                'verification_id' => $verification->verification_id,
                'type' => $verification->type, // nin, bvn, or vnin
                'status' => $verification->status, // pending, verified, or failed
                'value' => $verification->value, // The NIN/BVN/vNIN number
                'qoreid_reference' => $verification->qoreid_reference,
                'response_payload' => $verification->response_payload,
                'created_at' => $verification->created_at,
                'updated_at' => $verification->updated_at,
                'message' => $this->getStatusMessage($verification),
            ]);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Verification request not found.'
            ], 404);
        } catch (\Exception $e) {
            Log::error('Verification status check failed: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while checking verification status. Please try again later.'
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
