<?php

namespace App\Jobs;

use App\Models\Booking; // Inspection is handled by Booking model
use App\Models\Notification;
use App\Services\FCMService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendInspectionUpdateNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected int $inspectionId;
    protected string $eventType; // e.g., 'created', 'updated', 'status_changed'

    /**
     * Create a new job instance.
     *
     * @return void
     */
    public function __construct(int $inspectionId, string $eventType)
    {
        $this->inspectionId = $inspectionId;
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
        Log::info("SendInspectionUpdateNotificationJob started for inspection ID: {$this->inspectionId}, event: {$this->eventType}");

        $inspection = Booking::with(['user', 'agent', 'property'])->find($this->inspectionId);

        if (!$inspection) {
            Log::warning("Inspection {$this->inspectionId} not found. Skipping notification.");
            return;
        }

        $title = "Inspection Update: {$inspection->status}";
        $body = "Your inspection for property '{$inspection->property->title}' has been {$inspection->status}.";
        $data = [
            'inspectionId' => (string)$inspection->id,
            'propertyId' => (string)$inspection->property->id,
            'type' => 'inspection_update',
            'status' => $inspection->status,
        ];

        // Notify the user
        if ($inspection->user && $inspection->user->notificationSettings->push_notifications_enabled) {
            Notification::create([
                'receiver_id' => $inspection->user->id,
                'receiver_type' => 'user',
                'type' => 'inspection_update',
                'title' => $title,
                'body' => $body,
                'data' => $data,
                'is_read' => false,
            ]);

            $fcmService->sendToUserOrAgent(
                $inspection->user->id,
                'user',
                $title,
                $body,
                $data
            );
            Log::info("Inspection notification sent to user {$inspection->user->id} for inspection ID: {$this->inspectionId}");
        }

        // Notify the agent (if applicable and agent has notification settings enabled)
        if ($inspection->agent && $inspection->agent->notificationSettings->push_notifications_enabled) {
            $agentTitle = "Inspection Update: {$inspection->status}";
            $agentBody = "Inspection #{$inspection->id} for '{$inspection->property->title}' has been {$inspection->status}.";
            $agentData = [
                'inspectionId' => (string)$inspection->id,
                'propertyId' => (string)$inspection->property->id,
                'type' => 'inspection_update',
                'status' => $inspection->status,
            ];

            Notification::create([
                'receiver_id' => $inspection->agent->id,
                'receiver_type' => 'agent',
                'type' => 'inspection_update',
                'title' => $agentTitle,
                'body' => $agentBody,
                'data' => $agentData,
                'is_read' => false,
            ]);

            $fcmService->sendToUserOrAgent(
                $inspection->agent->id,
                'agent',
                $agentTitle,
                $agentBody,
                $agentData
            );
            Log::info("Inspection notification sent to agent {$inspection->agent->id} for inspection ID: {$this->inspectionId}");
        }
    }
}
