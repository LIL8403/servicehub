<?php

namespace Database\Seeders;

use App\Models\Payment;
use App\Models\ServiceRequest;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

/**
 * Sample payments tied to completed demo requests, so the customer
 * payment history and admin payments page have data.
 */
class DemoPaymentSeeder extends Seeder
{
    public function run(): void
    {
        $completedRequests = ServiceRequest::where('status', 'completed')
            ->limit(4)
            ->get();

        if ($completedRequests->isEmpty()) {
            $this->command->warn('No completed requests — skipping payment seeding.');
            return;
        }

        $count = 0;

        foreach ($completedRequests as $request) {
            Payment::updateOrCreate(
                ['reference' => 'demo-pay-' . substr((string) $request->_id, -8)],
                [
                    'reference' => 'demo-pay-' . substr((string) $request->_id, -8),
                    'service_request_id' => (string) $request->_id,
                    'customer_id' => $request->customer_id,
                    'artisan_id' => $request->selected_artisan_id,
                    'amount' => 45000 + (random_int(0, 30) * 1500),
                    'currency' => 'XAF',
                    'channel' => 'mtn_momo',
                    'purpose' => 'service',
                    'status' => 'released',
                    'initiated_at' => now()->subDays(5),
                    'held_at' => now()->subDays(4),
                    'released_at' => now()->subDays(1),
                    'external_reference' => 'MOMO-' . strtoupper(Str::random(10)),
                ],
            );

            $count++;
        }

        $this->command->info("Seeded {$count} demo payments.");
    }
}