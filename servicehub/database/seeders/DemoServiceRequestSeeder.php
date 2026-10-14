<?php

namespace Database\Seeders;

use App\Models\Artisan;
use App\Models\Service;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Sample service requests in various states so the customer home,
 * the artisan inbox, and the admin service-requests page all have
 * something to show.
 *
 * Creates 12 requests:
 *   - 4 pending artisan response
 *   - 3 booked / in progress
 *   - 2 completed
 *   - 1 cancelled
 *   - 2 awaiting artisan selection
 */
class DemoServiceRequestSeeder extends Seeder
{
    public function run(): void
    {
        $services = Service::all();
        $artisans = Artisan::where('verification_status', 'verified')->get();

        if ($services->isEmpty() || $artisans->isEmpty()) {
            $this->command->warn('Need services and verified artisans first — skipping.');
            return;
        }

        $customers = User::where('roles', 'all', ['customer'])
            ->where('email', 'like', '%@demo.cm')
            ->get();

        if ($customers->isEmpty()) {
            $this->command->warn('No demo customers found — skipping request seeding.');
            return;
        }

        $plumbing = $services->firstWhere('slug', 'plumbing-leak-repair');
        $electrical = $services->firstWhere('slug', 'electrical-socket-switch-repair');
        $carpentry = $services->firstWhere('slug', 'carpentry-furniture-assembly');
        $painting = $services->firstWhere('slug', 'painting-interior-wall-painting');

        $samples = [
            [
                'ref' => 'demo-req-001',
                'customer' => 0,
                'service' => $plumbing,
                'description' => 'My kitchen tap is dripping continuously and the sink is pooling water.',
                'status' => 'pending_artisan_response',
                'artisan' => 0,
            ],
            [
                'ref' => 'demo-req-002',
                'customer' => 1,
                'service' => $electrical,
                'description' => 'Two sockets in the living room are not working after a power surge.',
                'status' => 'pending_artisan_response',
                'artisan' => 1,
            ],
            [
                'ref' => 'demo-req-003',
                'customer' => 2,
                'service' => $carpentry,
                'description' => 'I need a custom wardrobe built for the master bedroom.',
                'status' => 'in_progress',
                'artisan' => 2,
            ],
            [
                'ref' => 'demo-req-004',
                'customer' => 3,
                'service' => $painting,
                'description' => 'Repaint the living room and hallway in a neutral beige.',
                'status' => 'booked',
                'artisan' => 3,
            ],
            [
                'ref' => 'demo-req-005',
                'customer' => 4,
                'service' => $plumbing,
                'description' => 'Water heater is leaking from the bottom. Need urgent repair.',
                'status' => 'completed',
                'artisan' => 4,
            ],
            [
                'ref' => 'demo-req-006',
                'customer' => 0,
                'service' => $electrical,
                'description' => 'Need ceiling fans installed in three bedrooms.',
                'status' => 'completed',
                'artisan' => 5,
            ],
            [
                'ref' => 'demo-req-007',
                'customer' => 1,
                'service' => $carpentry,
                'description' => 'The front door is difficult to close — needs adjustment or replacement.',
                'status' => 'cancelled',
                'artisan' => null,
            ],
            [
                'ref' => 'demo-req-008',
                'customer' => 2,
                'service' => $painting,
                'description' => 'Exterior wall of the house needs a fresh coat of weatherproof paint.',
                'status' => 'awaiting_artisan_selection',
                'artisan' => null,
            ],
            [
                'ref' => 'demo-req-009',
                'customer' => 3,
                'service' => $plumbing,
                'description' => 'Drain in the guest bathroom is slow.',
                'status' => 'awaiting_artisan_selection',
                'artisan' => null,
            ],
            [
                'ref' => 'demo-req-010',
                'customer' => 4,
                'service' => $electrical,
                'description' => 'Circuit breaker keeps tripping when the AC runs.',
                'status' => 'pending_artisan_response',
                'artisan' => 6,
            ],
            [
                'ref' => 'demo-req-011',
                'customer' => 0,
                'service' => $carpentry,
                'description' => 'Need shelves built for the home office.',
                'status' => 'in_progress',
                'artisan' => 7,
            ],
            [
                'ref' => 'demo-req-012',
                'customer' => 1,
                'service' => $painting,
                'description' => 'Touch-up paint needed after wall repairs.',
                'status' => 'pending_artisan_response',
                'artisan' => 8,
            ],

            [
                'ref' => 'demo-req-013',
                'customer' => 2,
                'service' => $electrical,
                'description' => 'Living room lights flicker when the AC turns on.',
                'status' => 'completed',
                'artisan' => 9,
            ],
            [
                'ref' => 'demo-req-014',
                'customer' => 3,
                'service' => $carpentry,
                'description' => 'Kitchen cabinet door is broken and needs replacing.',
                'status' => 'completed',
                'artisan' => 10,
            ],
            [
                'ref' => 'demo-req-015',
                'customer' => 4,
                'service' => $painting,
                'description' => 'Hallway needs repainting after water damage repair.',
                'status' => 'completed',
                'artisan' => 11,
            ],
            [
                'ref' => 'demo-req-016',
                'customer' => 0,
                'service' => $plumbing,
                'description' => 'Bathroom sink drains slowly. Needs clearing.',
                'status' => 'completed',
                'artisan' => 12,
            ],
            [
                'ref' => 'demo-req-017',
                'customer' => 1,
                'service' => $electrical,
                'description' => 'Outdoor security light stopped working.',
                'status' => 'completed',
                'artisan' => 13,
            ],
            [
                'ref' => 'demo-req-018',
                'customer' => 2,
                'service' => $carpentry,
                'description' => 'Bookshelf needs to be mounted to the wall.',
                'status' => 'completed',
                'artisan' => 14,
            ],
        ];

        $count = 0;

        foreach ($samples as $sample) {
            $customer = $customers[$sample['customer'] % $customers->count()];
            $service = $sample['service'];

            if (! $service) continue;

            $artisan = $sample['artisan'] !== null
                ? $artisans->get($sample['artisan'] % $artisans->count())
                : null;

            // Deterministic coordinates based on customer index.
            $lat = 3.848 + ($sample['customer'] * 0.015);
            $lng = 11.501 + ($sample['customer'] * 0.010);

            ServiceRequest::updateOrCreate(
                ['reference' => $sample['ref']],
                [
                    'reference' => $sample['ref'],
                    'customer_id' => (string) $customer->_id,
                    'service_id' => (string) $service->_id,
                    'description' => $sample['description'],
                    'status' => $sample['status'],
                    'selected_artisan_id' => $artisan ? (string) $artisan->_id : null,
                    'location' => [
                        'type' => 'Point',
                        'coordinates' => [$lng, $lat],
                        'label' => "Yaoundé, Cameroon",
                    ],
                    'formatted_address' => 'Yaoundé, Centre, Cameroon',
                    'preferred_schedule' => [
                        'date' => now()->addDays(3)->toDateString(),
                        'window' => '10:00 – 13:00',
                    ],
                    'ai_assist_enabled' => false,
                    'matching_attempts' => 1,
                    'status_history' => [
                        [
                            'status' => 'created',
                            'event' => 'submitted',
                            'occurred_at' => now()->subDays(2)->toIso8601String(),
                            'actor_id' => (string) $customer->_id,
                        ],
                    ],
                    'selection_history' => [],
                ],


            );

            $count++;
        }

        $this->command->info("Seeded {$count} demo service requests.");
    }
}
