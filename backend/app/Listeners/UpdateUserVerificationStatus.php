<?php

namespace App\Listeners;

use App\Events\VerificationUpdated;
use App\Models\User;
use App\Models\Agent;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Log;

class UpdateUserVerificationStatus
{
    /**
     * Create the event listener.
     *
     * @return void
     */
    public function __construct()
    {
        //
    }

    /**
     * Handle the event.
     *
     * @param  \App\Events\VerificationUpdated  $event
     * @return void
     */
    public function handle(VerificationUpdated $event)
    {
        $verification = $event->verification;

        if ($verification->status === 'verified') {
            if ($verification->receiver_type === 'user') {
                $user = User::find($verification->receiver_id);

                if ($user) {
                    if ($verification->type === 'nin' || $verification->type === 'vnin') {
                        $user->nin_verification = 1;
                        $user->save();
                        Log::info("User ID {$user->id} NIN verification status updated to verified.");
                    } elseif ($verification->type === 'bvn') {
                        $user->bvn_verification = 1;
                        $user->save();
                        Log::info("User ID {$user->id} BVN verification status updated to verified.");
                    }
                } else {
                    Log::warning("User not found for verified verification ID: " . $verification->id);
                }
            } elseif ($verification->receiver_type === 'agent') {
                $agent = Agent::find($verification->receiver_id);

                if ($agent) {
                    if ($verification->type === 'nin' || $verification->type === 'vnin') {
                        $agent->nin_verification = 1;
                        $agent->save();
                        Log::info("Agent ID {$agent->id} NIN verification status updated to verified.");
                    } elseif ($verification->type === 'bvn') {
                        $agent->bvn_verification = 1;
                        $agent->save();
                        Log::info("Agent ID {$agent->id} BVN verification status updated to verified.");
                    }
                } else {
                    Log::warning("Agent not found for verified verification ID: " . $verification->id);
                }
            }
        }
    }
}
