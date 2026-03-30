<?php

namespace App\Events;

use App\Models\Verification;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class VerificationUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    /**
     * The verification instance.
     *
     * @var \App\Models\Verification
     */
    public $verification;

    /**
     * Create a new event instance.
     *
     * @param \App\Models\Verification $verification
     * @return void
     */
    public function __construct(Verification $verification)
    {
        $this->verification = $verification;
    }

    public function broadcastOn()
    {
        // Broadcast on a private channel for the receiver (user or agent)
        if ($this->verification->receiver_type === 'agent') {
            return new PrivateChannel('agent.' . $this->verification->receiver_id);
        }
        return new PrivateChannel('user.' . $this->verification->receiver_id);
    }

    public function broadcastAs()
    {
        return 'verification.updated';
    }

    public function broadcastWith()
    {
        return ['verification' => $this->verification->toArray()];
    }
}
