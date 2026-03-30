<?php
// File: backend/app/Services/FCMService.php
namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Google\Auth\Credentials\ServiceAccountCredentials;
use App\Models\DeviceToken; // Import the DeviceToken model

class FCMService
{
    protected string $projectId;
    protected string $serviceAccountPath;

    public function __construct()
    {
        $this->projectId = env('FIREBASE_PROJECT_ID');
        $this->serviceAccountPath = storage_path('app/' . env('FCM_SERVICE_ACCOUNT_PATH'));

        Log::info('📲 FCM Service initialized', [
            'project_id' => $this->projectId,
        ]);

        if (empty($this->projectId)) {
            throw new \Exception("FIREBASE_PROJECT_ID is not set in .env");
        }
        if (!file_exists($this->serviceAccountPath)) {
            throw new \Exception("FCM_SERVICE_ACCOUNT_PATH file does not exist: {$this->serviceAccountPath}");
        }
    }

    /**
     * Get cached OAuth2 access token from Redis or generate a new one.
     */
    public function getAccessToken(): string
    {
        $cacheKey = 'fcm_access_token';
        $cached = cache()->get($cacheKey);
        if ($cached)
            return $cached;

        $credentials = new ServiceAccountCredentials(
            'https://www.googleapis.com/auth/firebase.messaging',
            json_decode(file_get_contents($this->serviceAccountPath), true)
        );

        $auth = $credentials->fetchAuthToken();

        if (!isset($auth['access_token'])) {
            throw new \Exception("Failed to obtain FCM access token.");
        }

        cache()->put($cacheKey, $auth['access_token'], 3540); // 59 min
        return $auth['access_token'];
    }

    /**
     * Send notifications to multiple tokens.
     */
    public function sendMany(array $tokens, string $title, string $body, array $data = [], string $receiverType = 'user')
    {
        Log::info('📲 FCM sendMany called', [
            'token_count' => count($tokens),
            'title' => $title,
            'body' => substr($body, 0, 50), // First 50 chars
            'receiver_type' => $receiverType,
        ]);

        if (empty($tokens)) {
            Log::warning('📲 No FCM tokens provided, skipping notification send');
            return;
        }

        $url = "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send";

        try {
            $accessToken = $this->getAccessToken();
            Log::info('📲 FCM access token obtained');
        } catch (\Exception $e) {
            Log::error('📲 Failed to get FCM access token: ' . $e->getMessage());
            return;
        }

        // Determine correct channel ID
        $channelId = $receiverType === 'agent' ? 'cribs_agents_channel_id' : 'cribs_arena_channel_id';

        $chunks = array_chunk($tokens, 100);
        $successCount = 0;
        $failCount = 0;

        foreach ($chunks as $chunk) {
            foreach ($chunk as $token) {
                if (empty($token)) {
                    Log::warning('📲 Empty FCM token encountered, skipping');
                    continue;
                }

                // Ensure title and body are strings
                $titleStr = is_string($title) ? $title : json_encode($title);
                $bodyStr = is_string($body) ? $body : json_encode($body);

                // Base notification payload
                $notificationPayload = ['title' => $titleStr, 'body' => $bodyStr];

                // Add title and body to data payload for foreground handling
                $messageData = $data; // Use a fresh copy for each token
                $messageData['title'] = $title;
                $messageData['body'] = $body;

                // ✅ IMPORTANT: FCM requires all data values to be strings
                $messageData = array_map(function ($value) use ($token) {
                    if (is_array($value)) {
                        Log::warning('📲 Nested array found in FCM data', ['key' => $value, 'token_truncated' => substr($token, 0, 15)]);
                        return json_encode($value);
                    }
                    return is_string($value) ? $value : (string) $value;
                }, $messageData);

                $payload = [
                    'message' => [
                        'token' => $token,
                        'notification' => $notificationPayload,
                        'data' => $messageData,
                        'apns' => [
                            'payload' => [
                                'aps' => [
                                    'mutable-content' => 0,
                                ],
                            ],
                        ],
                        'android' => [
                            'priority' => 'high',
                            'notification' => [
                                'channel_id' => $channelId,
                                'sound' => 'default',
                            ],
                        ],
                    ],
                ];

                try {
                    $response = Http::timeout(30)->withHeaders([
                        'Authorization' => "Bearer {$accessToken}",
                        'Content-Type' => 'application/json',
                    ])->post($url, $payload);

                    if ($response->successful()) {
                        $successCount++;
                        $responseBody = $response->json();
                        Log::info('📲 FCM send successful', [
                            'message_name' => $responseBody['name'] ?? 'unknown',
                            'token_truncated' => substr($token, 0, 15) . '...',
                        ]);
                    } else {
                        $failCount++;
                        $status = $response->status();
                        $errorBody = $response->json();

                        Log::error('📲 FCM send failed', [
                            'status' => $status,
                            'body' => $errorBody,
                            'token_truncated' => substr($token, 0, 15) . '...',
                        ]);

                        // Handle unregistered tokens (Stale)
                        if ($status === 404 || (isset($errorBody['error']['details'][0]['errorCode']) && $errorBody['error']['details'][0]['errorCode'] === 'UNREGISTERED')) {
                            Log::info('📲 Deleting unregistered token', ['token_truncated' => substr($token, 0, 15) . '...']);
                            DeviceToken::where('fcm_token', $token)->delete();
                        }
                    }
                } catch (\Exception $e) {
                    $failCount++;
                    Log::error("📲 FCM send exception: " . $e->getMessage());
                }
            }
        }

        Log::info('📲 FCM sendMany completed', [
            'total_tokens' => count($tokens),
            'success' => $successCount,
            'failed' => $failCount,
            'receiver_type' => $receiverType,
        ]);
    }

    /**
     * Send a notification to a specific user or agent.
     */
    public function sendToUserOrAgent(int $id, string $type, string $title, string $body, array $data = [])
    {
        $modelClass = $type === 'agent' ? \App\Models\Agent::class : \App\Models\User::class;
        $idField = $type === 'agent' ? 'agent_id' : 'user_id';

        // Try finding by primary key first, then by custom business ID
        $recipient = $modelClass::where('id', $id)->orWhere($idField, $id)->first();

        if (!$recipient) {
            Log::warning("📲 Recipient not found for FCM send: {$type} ID {$id}");
            return;
        }

        // Use the relationship to get tokens
        $tokens = $recipient->deviceTokens()->pluck('fcm_token')->toArray();

        if (empty($tokens)) {
            Log::info("📲 No FCM tokens found for {$type} ID: {$recipient->id}. Notification not sent.");
            return;
        }

        $this->sendMany($tokens, $title, $body, $data, $type);
    }

}
