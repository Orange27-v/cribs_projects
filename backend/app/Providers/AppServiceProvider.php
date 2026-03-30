<?php

namespace App\Providers;

use App\Models\Property;
use App\Observers\PropertyObserver;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        // Suppress PHP deprecation warnings
        error_reporting(E_ALL & ~E_DEPRECATED);
    }

    /**
     * Bootstrap any application services.
     *
     * @return void
     */

    public function boot()
    {
        Property::observe(PropertyObserver::class);

        Relation::morphMap([
            'user' => 'App\Models\User',
            'agent' => 'App\Models\Agent',
        ]);

        // Register Resend mail transport
        \Illuminate\Support\Facades\Mail::extend('resend', function () {
            return new \App\Mail\ResendTransport();
        });
    }
}

