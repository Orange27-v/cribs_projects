<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Helpers\NotificationHelper;

class SendInspectionNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $type;
    protected $userId;
    protected $agentId;
    protected $notificationType;
    protected $title;
    protected $message;
    protected $data;

    /**
     * Create a new job instance.
     */
    public function __construct(
        string $type,
        $userId,
        $agentId,
        string $notificationType,
        string $title,
        string $message,
        array $data = []
    ) {
        $this->type = $type;
        $this->userId = $userId;
        $this->agentId = $agentId;
        $this->notificationType = $notificationType;
        $this->title = $title;
        $this->message = $message;
        $this->data = $data;
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        if ($this->type === 'user' && $this->userId) {
            NotificationHelper::sendUserNotification(
                $this->userId,
                $this->notificationType,
                $this->title,
                $this->message,
                $this->data
            );
        }

        if ($this->type === 'agent' && $this->agentId) {
            NotificationHelper::sendAgentNotification(
                $this->agentId,
                $this->notificationType,
                $this->title,
                $this->message,
                $this->data
            );
        }
    }
}
