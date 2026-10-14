<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * Rich demo data for screenshots, QA, and stakeholder reviews.
 *
 * Run with:
 *   php artisan db:seed --class=DemoSeeder
 *
 * This is idempotent — safe to run multiple times. All records are
 * updateOrCreate'd by a stable key (email, slug, or a synthetic ref).
 *
 * Unlike the base DatabaseSeeder, this seeder:
 *   - Populates a full service catalogue (4 services per category)
 *   - Adds 20 artisans across Yaoundé and Douala districts
 *   - Spreads coordinates so the map view is meaningful
 *   - Adds demo customers, reviews, requests, and payments
 *
 * The base DatabaseSeeder remains minimal for quick smoke tests.
 */
class DemoSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            PlatformSettingsSeeder::class,
            DevelopmentUserSeeder::class,
            ServiceCatalogDemoSeeder::class,
            DemoCustomerSeeder::class,
            DemoArtisanSeeder::class,
            DemoServiceRequestSeeder::class,
            DemoReviewSeeder::class,
            DemoPaymentSeeder::class,
        ]);

        $this->command->newLine();
        $this->command->info('══════════════════════════════════════════════');
        $this->command->info('  Demo data seeded successfully');
        $this->command->info('══════════════════════════════════════════════');
        $this->command->newLine();
        $this->command->line('  Login credentials:');
        $this->command->line('    Admin    → admin@servicehub.test / Password123');
        $this->command->line('    Customer → customer@servicehub.test / Password123');
        $this->command->line('    Artisan  → artisan@servicehub.test / Password123');
        $this->command->newLine();
        $this->command->line('  Demo artisans (all use password "password"):');
        $this->command->line('    jean.mbarga@servicehub.cm       (Plumber, Yaoundé)');
        $this->command->line('    pauline.ngo@servicehub.cm       (Plumber, Douala)');
        $this->command->line('    eric.fotso@servicehub.cm        (Electrician, Yaoundé)');
        $this->command->line('    aline.tchoumi@servicehub.cm     (Electrician, Douala)');
        $this->command->line('    bernard.kamdem@servicehub.cm    (Carpenter, Yaoundé)');
        $this->command->line('    claudine.mbah@servicehub.cm     (Carpenter, Douala)');
        $this->command->line('    samuel.etoundi@servicehub.cm    (Plumber, Yaoundé)');
        $this->command->newLine();
    }
}