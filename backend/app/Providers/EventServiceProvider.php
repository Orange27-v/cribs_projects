<?php

namespace App\Providers;

use App\Models\Property;
use App\Observers\PropertyObserver;
use App\Models\Booking; // Import Booking model
use App\Observers\BookingObserver; // Import BookingObserver
use App\Observers\InspectionObserver; // Import InspectionObserver
use App\Models\Transaction; // Import Transaction model
use App\Observers\PaymentObserver; // Import PaymentObserver
use Illuminate\Auth\Events\Registered;
use Illuminate\Auth\Listeners\SendEmailVerificationNotification;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Event;

class EventServiceProvider extends ServiceProvider
{
    /**
     * The model observers for your application.
     *
     * @var array
     */
    protected $observers = [
        Property::class => [PropertyObserver::class],
        Booking::class => [BookingObserver::class, InspectionObserver::class],
        Transaction::class => [PaymentObserver::class], // Register PaymentObserver
    ];

    /**
     * The event to listener mappings for the application.
     *
     * @var array<class-string, array<int, class-string>>
     */
    protected $listen = [
        Registered::class => [
            SendEmailVerificationNotification::class,
        ],
        \App\Events\VerificationUpdated::class => [
            \App\Listeners\UpdateUserVerificationStatus::class,
        ],
    ];

    /**
     * Register any events for your application.
     *
     * @return void
     */
    public function boot()
    {
        //
    }

    /**
     * Determine if events and listeners should be automatically discovered.
     *
     * @return bool
     */
    public function shouldDiscoverEvents()
    {
        return false;
    }
}
