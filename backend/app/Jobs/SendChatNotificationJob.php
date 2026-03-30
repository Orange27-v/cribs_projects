<?php

namespace App\Jobs;

use App\Models\User;
use App\Models\Agent;
use App\Services\FCMService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendChatNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $message_uuid;
    protected $conversationId;
    protected $senderId;
    protected $receiverId;
    protected $messageContent;
    protected $timestamp;

    /**
     * Create a new job instance.
     *
     * @return void
     */
    public function __construct($message_uuid, $conversationId, $senderId, $receiverId, $messageContent, $timestamp)
    {
        $this->message_uuid = $message_uuid;
        $this->conversationId = $conversationId;
        $this->senderId = $senderId;
        $this->receiverId = $receiverId;
        $this->messageContent = $messageContent;
        $this->timestamp = $timestamp;
    }

    /**
     * Execute the job.
     *
     * @param  \App\Services\FCMService  $fcmService
     * @return void
     */
    public function handle(FCMService $fcmService)
    {
        // Find the recipient - check BOTH primary key and custom ID fields
        $recipient = User::where('id', $this->receiverId)->orWhere('user_id', $this->receiverId)->first();
        $receiverType = 'user';

        if (!$recipient) {
            $recipient = Agent::where('id', $this->receiverId)->orWhere('agent_id', $this->receiverId)->first();
            $receiverType = 'agent';
        }

        if (!$recipient) {
            Log::warning("Recipient with ID {$this->receiverId} not found for chat notification.");
            return;
        }

        // Resolve sender info to include in notification data
        $sender = User::where('id', $this->senderId)->orWhere('user_id', $this->senderId)->first();
        if (!$sender) {
            $sender = Agent::where('id', $this->senderId)->orWhere('agent_id', $this->senderId)->first();
        }

        $senderName = $sender ? "{$sender->first_name} {$sender->last_name}" : 'Someone';

        // Check if the user has push notifications and new message notifications enabled
        if ($recipient->notificationSettings && $recipient->notificationSettings->push_notifications_enabled && $recipient->notificationSettings->new_messages_enabled) {
            // Send push notification via FCM (NO database storage for chat notifications)
            // Use the primary key ID from the found recipient
            $fcmService->sendToUserOrAgent(
                $recipient->id,
                $receiverType,
                'New Message',
                $this->messageContent,
                [
                    'conversationId' => $this->conversationId,
                    'senderId' => $this->senderId,
                    'senderName' => $senderName,
                    'message_uuid' => $this->message_uuid,
                    'timestamp' => $this->timestamp,
                    'type' => 'chat',
                ]
            );
            Log::info("Chat push notification sent for recipient primary id: {$recipient->id}, message_uuid: {$this->message_uuid}");
        } else {
            Log::info("Chat push notification skipped for {$receiverType} {$this->receiverId} due to their settings.");
        }
    }
}
