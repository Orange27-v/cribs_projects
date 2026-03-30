<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class VerificationService
{
    protected $baseUrl;
    protected $tokenService;

    public function __construct(QoreidTokenService $tokenService)
    {
        $this->baseUrl = config('qoreid.base_url');
        $this->tokenService = $tokenService;
    }

    /**
     * Get authorization headers for QoreID API using Bearer token.
     *
     * @return array
     * @throws \Exception
     */
    protected function getAuthHeaders(): array
    {
        $token = $this->tokenService->getValidToken();

        return [
            'Authorization' => "Bearer {$token}",
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
        ];
    }

    /**
     * Verify NIN using QoreID Collections API.
     *
     * @param string $nin
     * @param array $data
     * @return array
     * @throws \Exception
     */
    public function verifyNin(string $nin, array $data): array
    {
        $url = "{$this->baseUrl}/v1/ng/identities/nin/{$nin}";

        $payload = [
            'firstname' => $data['firstname'] ?? null,
            'lastname' => $data['lastname'] ?? null,
        ];

        $headers = $this->getAuthHeaders();

        Log::info('QoreID NIN Verification Request', [
            'url' => $url,
            'payload' => $payload,
        ]);

        $response = Http::withHeaders($headers)
            ->timeout(30)
            ->post($url, $payload);

        Log::info('QoreID NIN Verification Response', [
            'status' => $response->status(),
            'headers' => $response->headers(),
            'body' => $response->json(),
        ]);

        if ($response->successful()) {
            return $response->json();
        }

        Log::error('NIN verification failed', [
            'status' => $response->status(),
            'response' => $response->body(),
        ]);
        throw new \Exception('NIN verification failed: ' . $response->body());
    }

    /**
     * Verify vNIN using QoreID Collections API.
     *
     * @param string $vnin
     * @param array $data
     * @return array
     * @throws \Exception
     */
    public function verifyVnin(string $vnin, array $data): array
    {
        $url = "{$this->baseUrl}/v1/ng/identities/vnin/{$vnin}";

        $payload = [
            'firstname' => $data['firstname'] ?? null,
            'lastname' => $data['lastname'] ?? null,
        ];

        Log::info('QoreID vNIN Verification Request', [
            'url' => $url,
            'payload' => $payload,
        ]);

        $response = Http::withHeaders($this->getAuthHeaders())
            ->timeout(30)
            ->post($url, $payload);

        Log::info('QoreID vNIN Verification Response', [
            'status' => $response->status(),
            'body' => $response->json(),
        ]);

        if ($response->successful()) {
            return $response->json();
        }

        Log::error('vNIN verification failed', ['response' => $response->body()]);
        throw new \Exception('vNIN verification failed: ' . $response->body());
    }

    /**
     * Verify BVN using QoreID Collections API.
     *
     * @param string $bvn
     * @param array $data
     * @return array
     * @throws \Exception
     */
    public function verifyBvn(string $bvn, array $data): array
    {
        $url = "{$this->baseUrl}/v1/ng/identities/bvn-basic/{$bvn}";

        $payload = [
            'firstname' => $data['firstname'] ?? null,
            'lastname' => $data['lastname'] ?? null,
            'dob' => $data['dob'] ?? null,
            'phone' => $data['phone'] ?? null,
            'email' => $data['email'] ?? null,
            'gender' => $data['gender'] ?? null,
        ];

        Log::info('QoreID BVN Verification Request', [
            'url' => $url,
            'payload' => $payload,
        ]);

        $response = Http::withHeaders($this->getAuthHeaders())
            ->timeout(30)
            ->post($url, $payload);

        Log::info('QoreID BVN Verification Response', [
            'status' => $response->status(),
            'body' => $response->json(),
        ]);

        if ($response->successful()) {
            return $response->json();
        }

        Log::error('BVN verification failed', ['response' => $response->body()]);
        throw new \Exception('BVN verification failed: ' . $response->body());
    }
}
