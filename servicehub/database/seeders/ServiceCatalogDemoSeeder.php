<?php

namespace Database\Seeders;

use App\Models\Service;
use App\Models\ServiceCategory;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

/**
 * Full service catalogue: 4 concrete services per category, so the
 * service picker in the request wizard has real choices.
 *
 * Idempotent — updateOrCreate'd by slug.
 */
class ServiceCatalogDemoSeeder extends Seeder
{
    public function run(): void
    {
        $catalog = [
            'plumbing' => [
                ['name' => 'Leak repair', 'description' => 'Fix dripping taps, burst pipes, or under-sink leaks'],
                ['name' => 'Pipe installation', 'description' => 'Install new water or drainage pipes'],
                ['name' => 'Drain unclogging', 'description' => 'Clear blocked sinks, toilets, or floor drains'],
                ['name' => 'Water heater repair', 'description' => 'Repair or replace water heaters and boilers'],
            ],
            'electrical' => [
                ['name' => 'Socket & switch repair', 'description' => 'Fix dead outlets, loose switches, or sparking sockets'],
                ['name' => 'Circuit breaker repair', 'description' => 'Diagnose and repair tripping breakers'],
                ['name' => 'Light installation', 'description' => 'Install ceiling lights, fans, or outdoor lighting'],
                ['name' => 'Wiring inspection', 'description' => 'Full electrical safety inspection and rewiring'],
            ],
            'carpentry' => [
                ['name' => 'Door repair & installation', 'description' => 'Fit, hang, or repair wooden doors'],
                ['name' => 'Furniture assembly', 'description' => 'Assemble or repair wardrobes, beds, and cabinets'],
                ['name' => 'Shelving & storage', 'description' => 'Build custom shelves and storage units'],
                ['name' => 'Window frame repair', 'description' => 'Repair or install wooden window frames'],
            ],
            'painting' => [
                ['name' => 'Interior wall painting', 'description' => 'Paint interior rooms and ceilings'],
                ['name' => 'Exterior painting', 'description' => 'Weatherproof exterior walls and façades'],
                ['name' => 'Touch-up & patching', 'description' => 'Fill holes and match existing paint'],
                ['name' => 'Wallpaper installation', 'description' => 'Hang wallpaper and decorative coverings'],
            ],
            'masonry' => [
                ['name' => 'Tile installation', 'description' => 'Lay ceramic, porcelain, or stone tiles'],
                ['name' => 'Wall construction', 'description' => 'Build or repair brick and block walls'],
                ['name' => 'Concrete work', 'description' => 'Slabs, foundations, and structural concrete'],
                ['name' => 'Plastering & rendering', 'description' => 'Smooth interior walls and exterior renders'],
            ],
            'mechanics' => [
                ['name' => 'Generator repair', 'description' => 'Service, repair, or install power generators'],
                ['name' => 'AC installation & service', 'description' => 'Install, clean, or repair air conditioners'],
                ['name' => 'Water pump repair', 'description' => 'Repair or install water pumps and boosters'],
                ['name' => 'Vehicle diagnostics', 'description' => 'Engine diagnostics and general mechanical repair'],
            ],
        ];

        foreach ($catalog as $categorySlug => $services) {
            $category = ServiceCategory::updateOrCreate(
                ['slug' => $categorySlug],
                [
                    'name' => Str::title(str_replace('-', ' ', $categorySlug)),
                    'description' => $this->categoryDescription($categorySlug),
                    'is_active' => true,
                ],
            );

            foreach ($services as $service) {
                $slug = Str::slug($categorySlug . '-' . $service['name']);

                Service::updateOrCreate(
                    ['slug' => $slug],
                    [
                        'service_category_id' => (string) $category->_id,
                        'name' => $service['name'],
                        'description' => $service['description'],
                        'is_active' => true,
                    ],
                );
            }

            $this->command->info(
                "Seeded {$category->name} with " . count($services) . ' services'
            );
        }
    }

    private function categoryDescription(string $slug): string
    {
        return match ($slug) {
            'plumbing' => 'Leaks, pipes, installations, and water systems',
            'electrical' => 'Wiring, sockets, repairs, and safety inspections',
            'carpentry' => 'Furniture, doors, shelving, and woodwork',
            'painting' => 'Interior, exterior, and decorative finishes',
            'masonry' => 'Walls, tiles, concrete, and structural work',
            'mechanics' => 'Vehicle, generator, and equipment repair',
            default => 'Professional trade services',
        };
    }
}