<?php

namespace Database\Seeders;

use App\Enums\AccountStatus;
use App\Enums\VerificationStatus;
use App\Models\Artisan;
use App\Models\Service;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class ArtisanSeeder extends Seeder
{
    public function run(): void
    {
        $catalog = Service::all()->keyBy('slug');

        $seed = [
            // Plumbing
            [
                'email' => 'jean.mbarga@servicehub.cm',
                'first_name' => 'Jean',
                'last_name' => 'Mbarga',
                'photo_slug' => 'jean',
                'phone' => '+237600000101',
                'service_slug' => 'plumbing',
                'title' => 'Senior Plumber',
                'description' => '10 years of experience with residential and commercial plumbing in Douala and Yaoundé.',
                'experience' => 10,
                'rating' => 4.8,
                'reviews' => 42,
                'jobs' => 87,
            ],
            [
                'email' => 'pauline.ngo@servicehub.cm',
                'first_name' => 'Pauline',
                'last_name' => 'Ngo Bassong',
                'photo_slug' => 'pauline',
                'phone' => '+237600000102',
                'service_slug' => 'plumbing',
                'title' => 'Certified Plumber',
                'description' => 'Specialized in emergency leak repairs and pipe installation.',
                'experience' => 7,
                'rating' => 4.6,
                'reviews' => 28,
                'jobs' => 51,
            ],
            [
                'email' => 'samuel.etoundi@servicehub.cm',
                'first_name' => 'Samuel',
                'last_name' => 'Etoundi',
                'photo_slug' => 'samuel',
                'phone' => '+237600000103',
                'service_slug' => 'plumbing',
                'title' => 'Plumber & Pipe Fitter',
                'description' => 'Residential plumbing and water tank installation.',
                'experience' => 5,
                'rating' => 4.4,
                'reviews' => 15,
                'jobs' => 32,
            ],
            // Electrical
            [
                'email' => 'eric.fotso@servicehub.cm',
                'first_name' => 'Eric',
                'last_name' => 'Fotso',
                'photo_slug' => 'eric',
                'phone' => '+237600000104',
                'service_slug' => 'electrical',
                'title' => 'Master Electrician',
                'description' => 'Licensed electrician with 12 years of experience in wiring and installation.',
                'experience' => 12,
                'rating' => 4.9,
                'reviews' => 61,
                'jobs' => 120,
            ],
            [
                'email' => 'aline.tchoumi@servicehub.cm',
                'first_name' => 'Aline',
                'last_name' => 'Tchoumi',
                'photo_slug' => 'aline',
                'phone' => '+237600000105',
                'service_slug' => 'electrical',
                'title' => 'Electrical Technician',
                'description' => 'Specializes in socket installation and circuit breaker repairs.',
                'experience' => 6,
                'rating' => 4.7,
                'reviews' => 34,
                'jobs' => 62,
            ],
            // Carpentry
            [
                'email' => 'bernard.kamdem@servicehub.cm',
                'first_name' => 'Bernard',
                'last_name' => 'Kamdem',
                'photo_slug' => 'bernard',
                'phone' => '+237600000106',
                'service_slug' => 'carpentry',
                'title' => 'Master Carpenter',
                'description' => 'Custom furniture, doors, and shelves. 15 years of experience.',
                'experience' => 15,
                'rating' => 4.8,
                'reviews' => 47,
                'jobs' => 98,
            ],
            [
                'email' => 'claudine.mbah@servicehub.cm',
                'first_name' => 'Claudine',
                'last_name' => 'Mbah',
                'photo_slug' => 'claudine',
                'phone' => '+237600000107',
                'service_slug' => 'carpentry',
                'title' => 'Furniture Carpenter',
                'description' => 'Bespoke furniture and interior woodwork.',
                'experience' => 8,
                'rating' => 4.5,
                'reviews' => 21,
                'jobs' => 44,
            ],
        ];

        foreach ($seed as $entry) {
            $service = $catalog[$entry['service_slug']] ?? null;

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
                ]
            );

            $photoSlug = $entry['photo_slug'] ?? null;
            if ($photoSlug) {
                $sourcePath = storage_path("app/seed/artisans/{$photoSlug}.jpg");
                if (file_exists($sourcePath)) {
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
            }

            $doualaPoint = [
                'type' => 'Point',
                'coordinates' => [9.7679, 4.0511],
            ];

            Artisan::updateOrCreate(
                ['user_id' => (string) $user->_id],
                [
                    'user_id' => (string) $user->_id,
                    'professional_title' => $entry['title'],
                    'professional_description' => $entry['description'],
                    'bio' => $entry['description'],
                    'experience_years' => $entry['experience'],
                    'verification_status' => VerificationStatus::VERIFIED->value,
                    'service_areas' => [
                        ['city' => 'Douala', 'radius_km' => 25],
                        ['city' => 'Yaoundé', 'radius_km' => 25],
                    ],
                    'service_offerings' => [
                        [
                            'service_reference' => (string) $service->_id,
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
                        'radius_km' => 25,
                        'accepting_requests' => true,
                        'monday' => [['start' => '08:00', 'end' => '18:00']],
                        'tuesday' => [['start' => '08:00', 'end' => '18:00']],
                        'wednesday' => [['start' => '08:00', 'end' => '18:00']],
                        'thursday' => [['start' => '08:00', 'end' => '18:00']],
                        'friday' => [['start' => '08:00', 'end' => '18:00']],
                    ],
                    'location' => $doualaPoint,
                    'service_location' => $doualaPoint,
                    'rating_average' => $entry['rating'],
                    'review_count' => $entry['reviews'],
                    'completed_jobs' => $entry['jobs'],
                    'response_rate' => 0.95,
                    'cancellation_rate' => 0.02,
                    'languages' => ['english', 'french'],
                    'certifications' => [],
                ]
            );

            $this->command->info("Seeded artisan: {$user->name} ({$entry['title']})");
        }
    }
}
