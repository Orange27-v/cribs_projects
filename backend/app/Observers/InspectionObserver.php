<?php

namespace App\Observers;

use App\Models\Booking; // Inspection is handled by Booking model
use App\Jobs\SendInspectionUpdateNotificationJob; // Import the job
use Illuminate\Support\Facades\Log;

class InspectionObserver
{
    /**
     * Handle the Booking "created" event.
     *
     * @param  \App\Models\Booking  $booking
     * @return void
     */
    public function created(Booking $booking)
    {
        Log::info("InspectionObserver 'created' method called for inspection ID: {$booking->id}");
        SendInspectionUpdateNotificationJob::dispatch($booking->id, 'created');
    }

    /**
     * Handle the Booking "updated" event.
     *
     * @param  \App\Models\Booking  $booking
     * @return void
     */
    public function updated(Booking $booking)
    {
        Log::info("InspectionObserver 'updated' method called for inspection ID: {$booking->id}");
        // Dispatch job only if status or other relevant fields changed
        if ($booking->isDirty('status')) {
            SendInspectionUpdateNotificationJob::dispatch($booking->id, 'status_changed');
        }
        // Add other conditions for dispatching on update if needed
    }

    /**
     * Handle the Booking "deleted" event.
     *
     * @param  \App\Models\Booking  $booking
     * @return void
     */
    public function deleted(Booking $booking)
    {
        //
    }

    /**
     * Handle the Booking "restored" event.
     *
     * @param  \App\Models\Booking  $booking
     * @return void
     */
    public function restored(Booking $booking)
    {
        //
    }

    /**
     * Handle the Booking "force deleted" event.
     *
     * @param  \App\Models\Booking  $booking
     * @return void
     */
    public function forceDeleted(Booking $booking)
    {
        //
    }
}
