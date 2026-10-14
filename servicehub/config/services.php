<?php

return [

    'campay' => [
        'mode' => env('CAMPAY_MODE', 'production'),
        'base_url' => env('CAMPAY_BASE_URL'),
        'username' => env('CAMPAY_USERNAME'),
        'password' => env('CAMPAY_PASSWORD'),
        'simulation_fail_on' => env('CAMPAY_SIMULATION_FAIL_ON'),
        'webhook_secret' => env('CAMPAY_WEBHOOK_SECRET'),
    ],

    'google_maps' => [
        'base_url' => env('GOOGLE_MAPS_GEOCODING_BASE_URL', 'https://maps.googleapis.com/maps/api/geocode/json'),
        'key' => env('GOOGLE_MAPS_SERVER_KEY'),
        'geocoding_enabled' => filter_var(env('GOOGLE_MAPS_GEOCODING_ENABLED', false), FILTER_VALIDATE_BOOLEAN),
        'cache_ttl' => (int) env('GOOGLE_MAPS_CACHE_TTL', 86400),
        'region' => env('GOOGLE_MAPS_REGION', 'cm'),
    ],

        'nominatim' => [
        'base_url' => env('NOMINATIM_BASE_URL', 'https://nominatim.openstreetmap.org'),
        'user_agent' => env('NOMINATIM_USER_AGENT', 'ServiceHUB/1.0 (contact: hello@servicehub.cm)'),
        'country_codes' => env('NOMINATIM_COUNTRY_CODES', 'cm'),
        'geocoding_enabled' => filter_var(env('NOMINATIM_GEOCODING_ENABLED', true), FILTER_VALIDATE_BOOLEAN),
        'cache_ttl' => env('NOMINATIM_CACHE_TTL', 86400),
    ],

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

];
