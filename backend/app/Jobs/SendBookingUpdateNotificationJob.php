<?php

namespace App\Jobs;

use App\Models\Booking;
use App\Models\Notification;
use App\Services\FCMService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendBookingUpdateNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected int $bookingId;
    protected string $eventType; // e.g., 'created', 'updated', 'status_changed'

    /**
     * Create a new job instance.
     *
     * @return void
     */
    public function __construct(int $bookingId, string $eventType)
    {
        $this->bookingId = $bookingId;
        $this->eventType = $eventType;
    }

    /**
     * Execute the job.
     *
     * @param  \App\Services\FCMService  $fcmService
     * @return void
     */
    public function handle(FCMService $fcmService)
    {
        Log::info("SendBookingUpdateNotificationJob started for booking ID: {$this->bookingId}, event: {$this->eventType}");

        $booking = Booking::with(['user', 'agent', 'property'])->find($this->bookingId);

        if (!$booking) {
            Log::warning("Booking {$this->bookingId} not found. Skipping notification.");
            return;
        }

        $title = "Booking Update: {$booking->status}";
        $body = "Your booking for property '{$booking->property->title}' has been {$booking->status}.";
        $data = [
            'bookingId' => (string)$booking->id,
            'propertyId' => (string)$booking->property->id,
            'type' => 'booking_update',
            'status' => $booking->status,
        ];

        // Notify the user
        if ($booking->user && $booking->user->notificationSettings->push_notifications_enabled) {
            Notification::create([
                'receiver_id' => $booking->user->id,
                'receiver_type' => 'user',
                'type' => 'booking_update',
                'title' => $title,
                'body' => $body,
                'data' => $data,
                'is_read' => false,
            ]);

            $fcmService->sendToUserOrAgent(
                $booking->user->id,
                'user',
                $title,
                $body,
                $data
            );
            Log::info("Booking notification sent to user {$booking->user->id} for booking ID: {$this->bookingId}");
        }

        // Notify the agent (if applicable and agent has notification settings enabled)
        if ($booking->agent && $booking->agent->notificationSettings->push_notifications_enabled) {
            $agentTitle = "Booking Update: {$booking->status}";
            $agentBody = "Booking #{$booking->id} for '{$booking->property->title}' has been {$booking->status}.";
            $agentData = [
                'bookingId' => (string)$booking->id,
                'propertyId' => (string)$booking->property->id,
                'type' => 'booking_update',
                'status' => $booking->status,
            ];

            Notification::create([
                'receiver_id' => $booking->agent->id,
                'receiver_type' => 'agent',
                'type' => 'booking_update',
                'title' => $agentTitle,
                'body' => $agentBody,
                'data' => $agentData,
                'is_read' => false,
            ]);

            $fcmService->sendToUserOrAgent(
                $booking->agent->id,
                'agent',
                $agentTitle,
                $agentBody,
                $agentData
            );
            Log::info("Booking notification sent to agent {$booking->agent->id} for booking ID: {$this->bookingId}");
        }
    }
}
