<?php
namespace App\Observers;

use App\Models\Property;
use App\Jobs\SendNewPropertyNotificationJob; // Updated job import
use Illuminate\Support\Facades\Log;

class PropertyObserver
{
    public function created(Property $property)
    {
        Log::info("PropertyObserver 'created' method called for property ID: {$property->id}");
        SendNewPropertyNotificationJob::dispatchSync($property->id); // Dispatch the new job
    }
}
