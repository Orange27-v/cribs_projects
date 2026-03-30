<?php

return [
    'mode' => env('QOREID_MODE', 'test'), // 'test' or 'live'
    'base_url' => env('QOREID_BASE', 'https://api.qoreid.com'),

    // Dynamically select keys based on mode
    // Collections API returns immediate results - no webhooks needed
    'public_key' => env('QOREID_MODE', 'test') === 'live'
        ? env('QOREID_LIVE_PUBLIC')
        : env('QOREID_TEST_PUBLIC'),

    'secret_key' => env('QOREID_MODE', 'test') === 'live'
        ? env('QOREID_LIVE_SECRET')
        : env('QOREID_TEST_SECRET'),
];
