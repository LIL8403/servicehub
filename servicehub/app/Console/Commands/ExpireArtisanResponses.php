<?php

namespace App\Console\Commands;

use App\Enums\ServiceRequestStatus;
use App\Models\PlatformSetting;
use App\Models\ServiceRequest;
use App\Services\ServiceRequest\ServiceRequestLifecycleService;
use Illuminate\Console\Command;

class ExpireArtisanResponses extends Command
{
    protected $signature = 'service-requests:expire-pending-responses';

    protected $description = 'Expire artisan selections that were not answered within the configured response window.';

    public function handle(ServiceRequestLifecycleService $lifecycle): int
    {
        $hours = max(1, (int) (PlatformSetting::query()->where('key', 'artisan_response_timeout_hours')->value('value') ?? 24));
        $cutoff = now()->subHours($hours);
        $expired = 0;

        ServiceRequest::query()
            ->where('status', ServiceRequestStatus::PENDING_ARTISAN_RESPONSE->value)
            ->where('pending_since', '<=', $cutoff)
            ->get()
            ->each(function (ServiceRequest $request) use ($lifecycle, &$expired): void {
                $lifecycle->timeoutPendingResponse($request);
                $expired++;
            });

        $this->info("Expired {$expired} pending artisan response(s).");

        return self::SUCCESS;
    }
}
