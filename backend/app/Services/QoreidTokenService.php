<?php

namespace App\Services;

use App\Models\QoreidToken;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class QoreidTokenService
{
    protected $baseUrl;
    protected $clientId;
    protected $secret;

    public function __construct()
    {
        $this->baseUrl = config('qoreid.base_url');
        $this->clientId = config('qoreid.public_key');
        $this->secret = config('qoreid.secret_key');
    }

    /**
     * Get a valid QoreID access token (from DB or generate new).
     *
     * @return string
     * @throws \Exception
     */
    public function getValidToken(): string
    {
        // Try to fetch an active, non-expired token from database
        $token = $this->fetchFromDatabase();

        if ($token) {
            // Mark token as used and return
            $token->markAsUsed();

            Log::info('QoreID: Reusing existing token', [
                'expires_at' => $token->expires_at,
                'created_at' => $token->created_at,
            ]);

            return $token->access_token;
        }

        // No valid token found, generate a new one
        return $this->generateAndStoreToken();
    }

    /**
     * Fetch a valid token from the database.
     *
     * @return QoreidToken|null
     */
    protected function fetchFromDatabase(): ?QoreidToken
    {
        return QoreidToken::where('expires_at', '>', now())
            ->latest()
            ->first();
    }

    /**
     * Generate a new token from QoreID API and store it in the database.
     *
     * @return string
     * @throws \Exception
     */
    protected function generateAndStoreToken(): string
    {
        $url = "{$this->baseUrl}/token";

        $payload = [
            'clientId' => $this->clientId,
            'secret' => $this->secret,
        ];

        Log::info('QoreID: Generating new access token', [
            'url' => $url,
            'clientId' => $this->clientId,
        ]);

        $response = Http::withHeaders([
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
        ])
            ->timeout(30)
            ->post($url, $payload);

        if (!$response->successful()) {
            Log::error('QoreID token generation failed', [
                'status' => $response->status(),
                'response' => $response->body(),
            ]);
            throw new \Exception('Failed to generate QoreID access token: ' . $response->body());
        }

        $data = $response->json();
        $accessToken = $data['accessToken'] ?? null;

        if (!$accessToken) {
            throw new \Exception('QoreID API did not return an access token');
        }

        // Store token in database with 2-hour expiry
        $this->storeToken($accessToken);

        Log::info('QoreID: New token generated and stored', [
            'expires_at' => now()->addHours(2),
        ]);

        return $accessToken;
    }

    /**
     * Store the access token in the database.
     *
     * @param string $accessToken
     * @return void
     */
    protected function storeToken(string $accessToken): void
    {
        QoreidToken::create([
            'access_token' => $accessToken,
            'expires_at' => now()->addHours(2), // QoreID tokens expire after 2 hours
            'last_used_at' => now(),
        ]);
    }
}
