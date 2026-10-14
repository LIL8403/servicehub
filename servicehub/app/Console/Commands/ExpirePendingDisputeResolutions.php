<?php

namespace App\Console\Commands;

use App\Services\DisputeResolutionService;
use Illuminate\Console\Command;

class ExpirePendingDisputeResolutions extends Command
{
    protected $signature = 'disputes:expire-pending-resolutions';

    protected $description = 'Return unconfirmed dispute financial resolutions to review after fifteen minutes';

    public function handle(DisputeResolutionService $resolutions): int
    {
        $this->components->info($resolutions->expireDueResolutions().' pending resolution(s) expired.');

        return self::SUCCESS;
    }
}
