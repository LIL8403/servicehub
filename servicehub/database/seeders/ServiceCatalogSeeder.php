<?php

namespace Database\Seeders;

use App\Models\Service;
use App\Models\ServiceCategory;
use Illuminate\Database\Seeder;

class ServiceCatalogSeeder extends Seeder
{
    /**
     * Seed the platform's service catalog with one service per category.
     *
     * Idempotent: safe to run multiple times.
     */
    public function run(): void
    {
        $catalog = [
            [
                'slug' => 'plumbing',
                'name' => 'Plumbing',
                'description' => 'Leaks, pipes, installations',
            ],
            [
                'slug' => 'electrical',
                'name' => 'Electrical',
                'description' => 'Wiring, sockets, repairs',
            ],
            [
                'slug' => 'carpentry',
                'name' => 'Carpentry',
                'description' => 'Furniture, doors, shelves',
            ],
            [
                'slug' => 'painting',
                'name' => 'Painting',
                'description' => 'Interior, exterior, touch-ups',
            ],
            [
                'slug' => 'masonry',
                'name' => 'Masonry',
                'description' => 'Walls, tiles, concrete',
            ],
            [
                'slug' => 'mechanics',
                'name' => 'Mechanics',
                'description' => 'Vehicle and equipment repair',
            ],
        ];

        foreach ($catalog as $entry) {
            $category = ServiceCategory::updateOrCreate(
                ['slug' => $entry['slug']],
                [
                    'name' => $entry['name'],
                    'description' => $entry['description'],
                    'is_active' => true,
                ],
            );

            Service::updateOrCreate(
                ['slug' => $entry['slug']],
                [
                    'service_category_id' => $category->_id,
                    'name' => $entry['name'],
                    'description' => $entry['description'],
                    'is_active' => true,
                ],
            );

            $this->command->info(
                "Seeded category and service: {$entry['name']}"
            );
        }
    }
}