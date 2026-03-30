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
use App\Models\Notification; // Import Notification model

class SendNewPropertyNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected int $propertyId;

    public function __construct(int $propertyId)
    {
        $this->propertyId = $propertyId;
    }

    public function handle(FCMService $fcm)
    {
        Log::info("SendNewPropertyNotificationJob started for property ID: {$this->propertyId}");

        $property = Property::find($this->propertyId);
        if (!$property) {
            Log::warning("Property {$this->propertyId} not found");
            return;
        }

        // Fetch users who want new listing notifications in the property's area
        // and whose notification settings allow new listing notifications
        $users = User::where('area', $property->location)
                     ->whereHas('notificationSettings', function ($query) {
                         $query->where('new_listings_enabled', true);
                     })
                     ->get();

        Log::info("Found " . $users->count() . " users for property ID: {$this->propertyId} in area: {$property->location}");

        if ($users->isEmpty()) {
            Log::info("No users found to send notifications for property ID: {$this->propertyId}");
            return;
        }

        $title = 'New Listing Near You!';
        $body = $property->title;
        $data = ['property_id' => (string)$property->id, 'type' => 'new_listing'];

        foreach ($users as $user) {
            // Create a notification record for each user
            Notification::create([
                'receiver_id' => $user->id,
                'receiver_type' => 'user',
                'type' => 'new_listing',
                'title' => $title,
                'body' => $body,
                'data' => $data,
                'is_read' => false,
            ]);

            // Send push notification via FCM
            $fcm->sendToUserOrAgent(
                $user->id,
                'user',
                $title,
                $body,
                $data
            );
        }

        Log::info("Notifications sent for property ID: {$this->propertyId}");
    }
}