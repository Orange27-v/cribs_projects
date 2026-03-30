<?php

namespace App\Jobs;

use App\Events\VerificationUpdated;
use App\Models\Verification;
use App\Services\VerificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class ProcessBvnVerification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $verification;
    protected $requestData;

    /**
     * Create a new job instance.
     *
     * @param Verification $verification
     * @param array $requestData
     * @return void
     */
    public function __construct(Verification $verification, array $requestData)
    {
        $this->verification = $verification;
        $this->requestData = $requestData;
    }

    /**
     * Execute the job.
     *
     * @param VerificationService $verificationService
     * @return void
     */
    public function handle(VerificationService $verificationService)
    {
        try {
            $qoreidResponse = $verificationService->verifyBvn($this->verification->value, $this->requestData);

            // Collections API returns immediate status in the response
            // Extract the verification status from the response
            $status = 'failed'; // Default to failed

            // Check for successful verification in the response
            if (isset($qoreidResponse['status']['state']) && $qoreidResponse['status']['state'] === 'verified') {
                $status = 'verified';
            } elseif (isset($qoreidResponse['status']['status']) && $qoreidResponse['status']['status'] === 'verified') {
                $status = 'verified';
            } elseif (
                isset($qoreidResponse['summary']['bvn_check']['status']) &&
                in_array($qoreidResponse['summary']['bvn_check']['status'], ['EXACT_MATCH', 'VERIFIED'])
            ) {
                $status = 'verified';
            }

            // Store the QoreID ID if available
            $qoreidId = $qoreidResponse['id'] ?? null;

            $this->verification->update([
                'status' => $status,
                'response_payload' => $qoreidResponse,
                'qoreid_reference' => $qoreidId, // Store QoreID's ID
            ]);

            // Fire event to update user table and notify frontend
            event(new VerificationUpdated($this->verification));

            Log::info('BVN verification completed', [
                'verification_id' => $this->verification->verification_id,
                'status' => $status,
            ]);

        } catch (\Exception $e) {
            Log::error('BVN verification job failed for verification_id: ' . $this->verification->verification_id, [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            $this->verification->update([
                'status' => 'failed',
                'response_payload' => ['error' => $e->getMessage()],
            ]);
            event(new VerificationUpdated($this->verification));
        }
    }
}
