<?php

namespace Database\Seeders;

use App\Enums\AccountStatus;
use App\Enums\VerificationStatus;
use App\Models\Artisan;
use App\Models\Customer;
use App\Models\Service;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

/**
 * Rich artisan dataset.
 *
 * Key improvements over the base ArtisanSeeder:
 *  - 20 artisans spread across 6 categories
 *  - Real Yaoundé + Douala district coordinates so the map is meaningful
 *  - Correct UTF-8 encoding (fixes the "YaoundÃ©" mojibake)
 *  - Mixed verification statuses (some pending, one rejected) for
 *    admin queue testing
 *  - Realistic ratings, review counts, and job counts
 */
class DemoArtisanSeeder extends Seeder
{
    /**
     * Real neighbourhood coordinates.
     *
     * Yaoundé spans roughly 3.75–4.00 lat, 11.40–11.60 lng.
     * Douala spans roughly 4.00–4.10 lat, 9.65–9.80 lng.
     */
    private const DISTRICTS = [
        'yaounde-messa'        => ['city' => 'Yaoundé', 'label' => 'Messa',        'lat' => 3.8480, 'lng' => 11.5010],
        'yaounde-bastos'       => ['city' => 'Yaoundé', 'label' => 'Bastos',       'lat' => 3.8860, 'lng' => 11.5110],
        'yaounde-biyem-assi'   => ['city' => 'Yaoundé', 'label' => 'Biyem-Assi',   'lat' => 3.8290, 'lng' => 11.4770],
        'yaounde-omnisports'   => ['city' => 'Yaoundé', 'label' => 'Omnisports',   'lat' => 3.8830, 'lng' => 11.5280],
        'yaounde-nlongkak'     => ['city' => 'Yaoundé', 'label' => 'Nlongkak',     'lat' => 3.8920, 'lng' => 11.5180],
        'yaounde-nsimeyong'    => ['city' => 'Yaoundé', 'label' => 'Nsimeyong',    'lat' => 3.8300, 'lng' => 11.5020],
        'yaounde-mvog-ada'     => ['city' => 'Yaoundé', 'label' => 'Mvog-Ada',     'lat' => 3.8550, 'lng' => 11.5220],
        'douala-akwa'          => ['city' => 'Douala',  'label' => 'Akwa',         'lat' => 4.0490, 'lng' => 9.7020],
        'douala-bonapriso'     => ['city' => 'Douala',  'label' => 'Bonapriso',    'lat' => 4.0280, 'lng' => 9.6940],
        'douala-bonaberi'      => ['city' => 'Douala',  'label' => 'Bonabéri',     'lat' => 4.0720, 'lng' => 9.6820],
        'douala-deido'         => ['city' => 'Douala',  'label' => 'Deido',        'lat' => 4.0670, 'lng' => 9.7020],
        'douala-bali'          => ['city' => 'Douala',  'label' => 'Bali',         'lat' => 4.0390, 'lng' => 9.7160],
    ];

    public function run(): void
    {
        $services = Service::all()->keyBy('slug');

        $artisans = $this->artisanData();

        foreach ($artisans as $index => $entry) {
            $service = $services[$entry['service_slug']] ?? null;

            if (! $service) {
                $this->command->warn(
                    "Skipping {$entry['email']}: service '{$entry['service_slug']}' not found."
                );
                continue;
            }

            $user = User::updateOrCreate(
                ['email' => $entry['email']],
                [
                    'first_name' => $entry['first_name'],
                    'last_name' => $entry['last_name'],
                    'name' => "{$entry['first_name']} {$entry['last_name']}",
                    'phone' => $entry['phone'],
                    'password' => Hash::make('password'),
                    'email_verified_at' => now(),
                    'account_status' => AccountStatus::ACTIVE->value,
                    'status' => AccountStatus::ACTIVE->value,
                    'roles' => ['customer', 'artisan'],
                    'active_role' => 'artisan',
                ],
            );

            Customer::updateOrCreate(
                ['user_id' => (string) $user->_id],
                ['user_id' => (string) $user->_id],
            );

            $this->attachProfilePhoto($user, $entry['photo_slug'] ?? null);

            $district = self::DISTRICTS[$entry['district']];
            $point = [
                'type' => 'Point',
                'coordinates' => [$district['lng'], $district['lat']],
            ];

            Artisan::updateOrCreate(
                ['user_id' => (string) $user->_id],
                [
                    'user_id' => (string) $user->_id,
                    'professional_title' => $entry['title'],
                    'professional_description' => $entry['description'],
                    'bio' => $entry['description'],
                    'experience_years' => $entry['experience'],
                    'verification_status' => $entry['verification_status'],
                    'rejection_reason' => $entry['rejection_reason'] ?? null,
                    'service_areas' => [
                        ['city' => $district['city'], 'radius_km' => 20],
                        ['city' => $district['city'] === 'Yaoundé' ? 'Douala' : 'Yaoundé', 'radius_km' => 15],
                    ],
                    'service_offerings' => [
                        [
                            'offering_id' => (string) \Illuminate\Support\Str::uuid(),
                            'service_reference' => (string) $service->_id,
                            'starting_price' => null,
                            'description' => null,
                            'is_active' => true,
                        ],
                    ],
                    'offered_services' => [
                        [
                            'service_reference' => (string) $service->_id,
                            'is_active' => true,
                        ],
                    ],
                    'availability' => [
                        'radius_km' => 20,
                        'accepting_requests' => $entry['accepting_requests'] ?? true,
                        'monday' => [['start' => '08:00', 'end' => '18:00']],
                        'tuesday' => [['start' => '08:00', 'end' => '18:00']],
                        'wednesday' => [['start' => '08:00', 'end' => '18:00']],
                        'thursday' => [['start' => '08:00', 'end' => '18:00']],
                        'friday' => [['start' => '08:00', 'end' => '18:00']],
                        'saturday' => [['start' => '08:00', 'end' => '14:00']],
                    ],
                    'location' => $point,
                    'service_location' => $point,
                    'rating_average' => $entry['rating'],
                    'review_count' => $entry['reviews'],
                    'completed_jobs' => $entry['jobs'],
                    'cancellation_rate' => $entry['cancellation_rate'] ?? 0.02,
                    'response_rate' => $entry['response_rate'] ?? 0.95,
                    'languages' => ['english', 'french'],
                    'certifications' => [],
                ],
            );

            $this->command->info(
                "Seeded artisan: {$user->name} ({$entry['title']}, {$district['label']})"
            );
        }
    }

    private function attachProfilePhoto(User $user, ?string $slug): void
    {
        if (! $slug) return;

        $sourcePath = storage_path("app/seed/artisans/{$slug}.jpg");
        if (! file_exists($sourcePath)) {
            $this->command->warn("Photo not found for {$slug}, skipping.");
            return;
        }

        $destination = "profile-photos/{$user->_id}/avatar.jpg";
        Storage::disk('local')->put($destination, file_get_contents($sourcePath));

        $user->forceFill([
            'profile_photo' => [
                'path' => $destination,
                'mime_type' => 'image/jpeg',
                'size' => filesize($sourcePath),
            ],
        ])->save();
    }

    /**
     * 20 artisans across the 6 categories.
     *
     * 15 verified, 4 pending, 1 rejected — gives the admin queue
     * something to review.
     */
    private function artisanData(): array
    {
        return [
            // ─── Plumbing (4) ───
            [
                'email' => 'jean.mbarga@servicehub.cm',
                'first_name' => 'Jean',
                'last_name' => 'Mbarga',
                'photo_slug' => 'jean',
                'phone' => '+237600000101',
                'service_slug' => 'plumbing-leak-repair',
                'title' => 'Senior Plumber',
                'district' => 'yaounde-messa',
                'description' => '10 years of experience with residential and commercial plumbing in Douala and Yaoundé.',
                'experience' => 10,
                'rating' => 4.8,
                'reviews' => 42,
                'jobs' => 87,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],
            [
                'email' => 'pauline.ngo@servicehub.cm',
                'first_name' => 'Pauline',
                'last_name' => 'Ngo Bassong',
                'photo_slug' => 'pauline',
                'phone' => '+237600000102',
                'service_slug' => 'plumbing-leak-repair',
                'title' => 'Certified Plumber',
                'district' => 'douala-akwa',
                'description' => 'Specialized in emergency leak repairs and pipe installation.',
                'experience' => 7,
                'rating' => 4.6,
                'reviews' => 28,
                'jobs' => 51,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],
            [
                'email' => 'samuel.etoundi@servicehub.cm',
                'first_name' => 'Samuel',
                'last_name' => 'Etoundi',
                'photo_slug' => 'samuel',
                'phone' => '+237600000103',
                'service_slug' => 'plumbing-pipe-installation',
                'title' => 'Plumber & Pipe Fitter',
                'district' => 'yaounde-bastos',
                'description' => 'Residential plumbing and water tank installation.',
                'experience' => 5,
                'rating' => 4.4,
                'reviews' => 15,
                'jobs' => 32,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],
            [
                'email' => 'cedric.mbappe@servicehub.cm',
                'first_name' => 'Cédric',
                'last_name' => 'Mbappé',
                'photo_slug' => null,
                'phone' => '+237600000108',
                'service_slug' => 'plumbing-drain-unclogging',
                'title' => 'Emergency Drain Specialist',
                'district' => 'douala-bonapriso',
                'description' => 'Fast drain clearing and plumbing maintenance.',
                'experience' => 4,
                'rating' => 4.3,
                'reviews' => 12,
                'jobs' => 27,
                'verification_status' => VerificationStatus::PENDING->value,
            ],

            // ─── Electrical (4) ───
            [
                'email' => 'eric.fotso@servicehub.cm',
                'first_name' => 'Eric',
                'last_name' => 'Fotso',
                'photo_slug' => 'eric',
                'phone' => '+237600000104',
                'service_slug' => 'electrical-wiring-inspection',
                'title' => 'Master Electrician',
                'district' => 'yaounde-omnisports',
                'description' => 'Licensed electrician with 12 years of experience in wiring and installation.',
                'experience' => 12,
                'rating' => 4.9,
                'reviews' => 61,
                'jobs' => 120,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],
            [
                'email' => 'aline.tchoumi@servicehub.cm',
                'first_name' => 'Aline',
                'last_name' => 'Tchoumi',
                'photo_slug' => 'aline',
                'phone' => '+237600000105',
                'service_slug' => 'electrical-socket-switch-repair',
                'title' => 'Electrical Technician',
                'district' => 'douala-bonapriso',
                'description' => 'Specializes in socket installation and circuit breaker repairs.',
                'experience' => 6,
                'rating' => 4.7,
                'reviews' => 34,
                'jobs' => 62,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],
            [
                'email' => 'pascal.eyenga@servicehub.cm',
                'first_name' => 'Pascal',
                'last_name' => 'Eyenga',
                'photo_slug' => null,
                'phone' => '+237600000109',
                'service_slug' => 'electrical-light-installation',
                'title' => 'Lighting Installer',
                'district' => 'yaounde-nlongkak',
                'description' => 'Indoor and outdoor lighting installation and repair.',
                'experience' => 8,
                'rating' => 4.6,
                'reviews' => 22,
                'jobs' => 41,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],
            [
                'email' => 'marie.njock@servicehub.cm',
                'first_name' => 'Marie',
                'last_name' => 'Njock',
                'photo_slug' => null,
                'phone' => '+237600000110',
                'service_slug' => 'electrical-circuit-breaker-repair',
                'title' => 'Electrical Safety Specialist',
                'district' => 'douala-deido',
                'description' => 'Circuit diagnostics and safety certification.',
                'experience' => 9,
                'rating' => 4.8,
                'reviews' => 38,
                'jobs' => 67,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],

            // ─── Carpentry (3) ───
            [
                'email' => 'bernard.kamdem@servicehub.cm',
                'first_name' => 'Bernard',
                'last_name' => 'Kamdem',
                'photo_slug' => 'bernard',
                'phone' => '+237600000106',
                'service_slug' => 'carpentry-furniture-assembly',
                'title' => 'Master Carpenter',
                'district' => 'yaounde-biyem-assi',
                'description' => 'Custom furniture, doors, and shelves. 15 years of experience.',
                'experience' => 15,
                'rating' => 4.8,
                'reviews' => 47,
                'jobs' => 98,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],
            [
                'email' => 'claudine.mbah@servicehub.cm',
                'first_name' => 'Claudine',
                'last_name' => 'Mbah',
                'photo_slug' => 'claudine',
                'phone' => '+237600000107',
                'service_slug' => 'carpentry-shelving-storage',
                'title' => 'Furniture Carpenter',
                'district' => 'douala-akwa',
                'description' => 'Bespoke furniture and interior woodwork.',
                'experience' => 8,
                'rating' => 4.5,
                'reviews' => 21,
                'jobs' => 44,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],
            [
                'email' => 'roger.tabi@servicehub.cm',
                'first_name' => 'Roger',
                'last_name' => 'Tabi',
                'photo_slug' => null,
                'phone' => '+237600000111',
                'service_slug' => 'carpentry-door-repair-installation',
                'title' => 'Door & Window Craftsman',
                'district' => 'yaounde-nsimeyong',
                'description' => 'Custom wooden doors and window frames.',
                'experience' => 11,
                'rating' => 4.7,
                'reviews' => 30,
                'jobs' => 55,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],

            // ─── Painting (3) ───
            [
                'email' => 'estelle.mbala@servicehub.cm',
                'first_name' => 'Estelle',
                'last_name' => 'Mbala',
                'photo_slug' => null,
                'phone' => '+237600000112',
                'service_slug' => 'painting-interior-wall-painting',
                'title' => 'Interior Painter',
                'district' => 'yaounde-mvog-ada',
                'description' => 'Interior wall painting and finishes.',
                'experience' => 6,
                'rating' => 4.6,
                'reviews' => 24,
                'jobs' => 48,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],
            [
                'email' => 'francois.ateba@servicehub.cm',
                'first_name' => 'François',
                'last_name' => 'Ateba',
                'photo_slug' => null,
                'phone' => '+237600000113',
                'service_slug' => 'painting-exterior-painting',
                'title' => 'Exterior Painting Specialist',
                'district' => 'douala-bonaberi',
                'description' => 'Weatherproof exterior painting.',
                'experience' => 10,
                'rating' => 4.5,
                'reviews' => 19,
                'jobs' => 37,
                'verification_status' => VerificationStatus::PENDING->value,
            ],
            [
                'email' => 'sandrine.efoua@servicehub.cm',
                'first_name' => 'Sandrine',
                'last_name' => 'Efoua',
                'photo_slug' => null,
                'phone' => '+237600000114',
                'service_slug' => 'painting-wallpaper-installation',
                'title' => 'Decorative Finishes',
                'district' => 'yaounde-bastos',
                'description' => 'Wallpaper and decorative finishes.',
                'experience' => 5,
                'rating' => 4.4,
                'reviews' => 14,
                'jobs' => 26,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],

            // ─── Masonry (3) ───
            [
                'email' => 'gabriel.biyick@servicehub.cm',
                'first_name' => 'Gabriel',
                'last_name' => 'Biyick',
                'photo_slug' => null,
                'phone' => '+237600000115',
                'service_slug' => 'masonry-tile-installation',
                'title' => 'Tile Installation Expert',
                'district' => 'yaounde-messa',
                'description' => 'Ceramic, porcelain, and stone tile installation.',
                'experience' => 12,
                'rating' => 4.7,
                'reviews' => 41,
                'jobs' => 78,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],
            [
                'email' => 'victor.ndjock@servicehub.cm',
                'first_name' => 'Victor',
                'last_name' => 'Ndjock',
                'photo_slug' => null,
                'phone' => '+237600000116',
                'service_slug' => 'masonry-wall-construction',
                'title' => 'Mason',
                'district' => 'douala-bali',
                'description' => 'Brick and block wall construction.',
                'experience' => 14,
                'rating' => 4.6,
                'reviews' => 33,
                'jobs' => 61,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],
            [
                'email' => 'rosalie.tchaptchet@servicehub.cm',
                'first_name' => 'Rosalie',
                'last_name' => 'Tchaptchet',
                'photo_slug' => null,
                'phone' => '+237600000117',
                'service_slug' => 'masonry-plastering-rendering',
                'title' => 'Plastering Specialist',
                'district' => 'yaounde-biyem-assi',
                'description' => 'Interior plastering and exterior rendering.',
                'experience' => 7,
                'rating' => 4.5,
                'reviews' => 18,
                'jobs' => 35,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],

            // ─── Mechanics (3) ───
            [
                'email' => 'thierry.nkolo@servicehub.cm',
                'first_name' => 'Thierry',
                'last_name' => 'Nkolo',
                'photo_slug' => null,
                'phone' => '+237600000118',
                'service_slug' => 'mechanics-generator-repair',
                'title' => 'Generator Technician',
                'district' => 'yaounde-nlongkak',
                'description' => 'Generator service, repair, and installation.',
                'experience' => 9,
                'rating' => 4.8,
                'reviews' => 36,
                'jobs' => 72,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],
            [
                'email' => 'huguette.mbarga@servicehub.cm',
                'first_name' => 'Huguette',
                'last_name' => 'Mbarga',
                'photo_slug' => null,
                'phone' => '+237600000119',
                'service_slug' => 'mechanics-ac-installation-service',
                'title' => 'AC Specialist',
                'district' => 'douala-akwa',
                'description' => 'Air conditioner installation, cleaning, and repair.',
                'experience' => 6,
                'rating' => 4.6,
                'reviews' => 27,
                'jobs' => 54,
                'verification_status' => VerificationStatus::VERIFIED->value,
            ],
            [
                'email' => 'olivier.tchoua@servicehub.cm',
                'first_name' => 'Olivier',
                'last_name' => 'Tchoua',
                'photo_slug' => null,
                'phone' => '+237600000120',
                'service_slug' => 'mechanics-vehicle-diagnostics',
                'title' => 'Vehicle Diagnostics',
                'district' => 'douala-deido',
                'description' => 'Engine diagnostics and general mechanical repair.',
                'experience' => 13,
                'rating' => 4.7,
                'reviews' => 44,
                'jobs' => 89,
                'verification_status' => VerificationStatus::PENDING->value,
            ],
        ];
    }
}
