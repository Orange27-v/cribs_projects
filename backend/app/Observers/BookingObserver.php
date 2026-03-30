<?php

namespace App\Observers;

use App\Models\Booking;
use App\Jobs\SendBookingUpdateNotificationJob; // Import the job
use Illuminate\Support\Facades\Log;

class BookingObserver
{
    /**
     * Handle the Booking "created" event.
     *
     * @param  \App\Models\Booking  $booking
     * @return void
     */
    public function created(Booking $booking)
    {
        Log::info("BookingObserver 'created' method called for booking ID: {$booking->id}");
        SendBookingUpdateNotificationJob::dispatch($booking->id, 'created');
    }

    /**
     * Handle the Booking "updated" event.
     *
     * @param  \App\Models\Booking  $booking
     * @return void
     */
    public function updated(Booking $booking)
    {
        Log::info("BookingObserver 'updated' method called for booking ID: {$booking->id}");
        // Dispatch job only if status or other relevant fields changed
        if ($booking->isDirty('status')) {
            SendBookingUpdateNotificationJob::dispatch($booking->id, 'status_changed');
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
