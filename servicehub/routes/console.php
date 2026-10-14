<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Schedule::command('disputes:expire-pending-resolutions')->everyMinute()->withoutOverlapping();
Schedule::command('auth:clear-resets')->everyFifteenMinutes()->withoutOverlapping();
Schedule::command('service-requests:expire-pending-responses')->everyFifteenMinutes()->withoutOverlapping();
