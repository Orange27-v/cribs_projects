<?php

namespace App\Http\Controllers\Verification;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Verification;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Auth;
use App\Services\VerificationService; // Import the service
use App\Jobs\ProcessBvnVerification; // Import the job
use Illuminate\Support\Facades\Log;

class BvnController extends Controller
{
    protected $verificationService;

    public function __construct(VerificationService $verificationService)
    {
        $this->verificationService = $verificationService;
    }

    public function verify(Request $request)
    {
        $validatedData = $request->validate([
            'bvn' => 'required|string|digits:11',
            'firstname' => 'required|string',
            'lastname' => 'required|string',
            'dob' => 'nullable|date_format:Y-m-d',
            'phone' => 'nullable|string',
            'email' => 'nullable|email',
            'gender' => 'nullable|string|in:Male,Female',
        ]);

        try {
            $user = Auth::user();
            $receiverType = $user instanceof \App\Models\Agent ? 'agent' : 'user';

            $verification = Verification::create([
                'receiver_id' => $user->id,
                'receiver_type' => $receiverType,
                'type' => 'bvn',
                'value' => $request->bvn,
                'status' => 'pending',
                'verification_id' => (string) Str::uuid(),
                'qoreid_reference' => null, // Collections API doesn't use customerReference
                'response_payload' => null,
            ]);

            // Dispatch the job to process the verification in the background
            ProcessBvnVerification::dispatch($verification, $validatedData);

            return response()->json([
                'verification_id' => $verification->verification_id,
                'status' => 'pending',
                'message' => 'BVN verification has been initiated.',
            ]);
        } catch (\Exception $e) {
            Log::error('BVN verification failed to initiate: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while initiating BVN verification. Please try again later.'
            ], 500);
        }
    }
}
