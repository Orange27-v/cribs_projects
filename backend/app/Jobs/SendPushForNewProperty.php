<?php
namespace App\Jobs;

use App\Models\Property;
use App\Models\User;
use App\Services\FCMService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendPushForNewProperty implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected int $propertyId;

    public function __construct(int $propertyId)
    {
        $this->propertyId = $propertyId;
    }

    public function handle(FCMService $fcm)
    {
        Log::info("SendPushForNewProperty started for property ID: {$this->propertyId}");

        $property = Property::find($this->propertyId);
        if (!$property) {
            Log::warning("Property {$this->propertyId} not found");
            return;
        }

        $users = User::where('area', $property->location)
            ->where('notif_new_listings', true)
            ->with('tokens')
            ->get();

        Log::info("Found " . $users->count() . " users for property ID: {$this->propertyId} in area: {$property->location}");

        if ($users->isEmpty()) {
            Log::info("No users found to send notifications for property ID: {$this->propertyId}");
            return;
        }

        $tokens = $users->flatMap(fn($u) => $u->tokens->pluck('fcm_token'))
            ->unique()
            ->values()
            ->all();

        Log::info("Collected " . count($tokens) . " FCM tokens for property ID: {$this->propertyId}");

        if (empty($tokens)) {
            Log::info("No FCM tokens collected for property ID: {$this->propertyId}");
            return;
        }

        $title = 'New Listing Near You!';
        $body = $property->title;
        $data = ['propertyId' => (string) $property->id, 'type' => 'new_listing'];

        $fcm->sendMany($tokens, $title, $body, $data);

        Log::info("Notifications sent for property ID: {$this->propertyId}");
    }
}
