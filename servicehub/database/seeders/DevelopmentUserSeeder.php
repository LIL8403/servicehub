<?php

namespace Database\Seeders;

use App\Enums\VerificationStatus;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DevelopmentUserSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::updateOrCreate(
            [
                'email' => 'admin@servicehub.test',
            ],
            [
                'name' => 'ServiceHUB Administrator',
                'phone' => '677000000',
                'password' => Hash::make('Password123'),
                'status' => 'active',
            ]
        );

        $admin->syncRoles(['admin']);

        $customer = User::updateOrCreate(
            [
                'email' => 'customer@servicehub.test',
            ],
            [
                'name' => 'Test Customer',
                'phone' => '677000001',
                'password' => Hash::make('Password123'),
                'status' => 'active',
            ]
        );

        $customer->syncRoles(['customer']);

        $artisan = User::updateOrCreate(
            [
                'email' => 'artisan@servicehub.test',
            ],
            [
                'name' => 'Test Artisan',
                'phone' => '677000002',
                'password' => Hash::make('Password123'),
                'status' => 'active',
            ]
        );

        $artisan->syncRoles(['artisan', 'customer']);

        $artisan->customer()->firstOrCreate(['user_id' => $artisan->getKey()]);
        $artisan->artisan()->updateOrCreate(
            [
                'user_id' => $artisan->id,
            ],
            [
                'professional_title' => 'Professional Plumber',
                'bio' => 'Experienced plumber providing residential plumbing services.',
                'professional_description' => 'Experienced plumber providing residential plumbing services.',
                'experience_years' => 5,
                'verification_status' => VerificationStatus::PENDING,
                'rejection_reason' => null,
                'reviewed_at' => null,
            ]
        );
    }
}
