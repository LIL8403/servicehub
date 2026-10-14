<?php

namespace Database\Seeders;

use App\Enums\AccountStatus;
use App\Models\Customer;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Demo customers so the admin user list and payment history aren't
 * empty. All use password "password" for quick demo logins.
 */
class DemoCustomerSeeder extends Seeder
{
    public function run(): void
    {
        $customers = [
            ['first' => 'Aïcha', 'last' => 'Tchamba', 'email' => 'aicha.tchamba@demo.cm', 'phone' => '+237690100001'],
            ['first' => 'Ferdinand', 'last' => 'Ngué', 'email' => 'ferdinand.ngue@demo.cm', 'phone' => '+237690100002'],
            ['first' => 'Mireille', 'last' => 'Fongang', 'email' => 'mireille.fongang@demo.cm', 'phone' => '+237690100003'],
            ['first' => 'Bertrand', 'last' => 'Mvondo', 'email' => 'bertrand.mvondo@demo.cm', 'phone' => '+237690100004'],
            ['first' => 'Sylvie', 'last' => 'Ndongo', 'email' => 'sylvie.ndongo@demo.cm', 'phone' => '+237690100005'],
        ];

        foreach ($customers as $entry) {
            $user = User::updateOrCreate(
                ['email' => $entry['email']],
                [
                    'first_name' => $entry['first'],
                    'last_name' => $entry['last'],
                    'name' => "{$entry['first']} {$entry['last']}",
                    'phone' => $entry['phone'],
                    'password' => Hash::make('password'),
                    'email_verified_at' => now(),
                    'account_status' => AccountStatus::ACTIVE->value,
                    'status' => AccountStatus::ACTIVE->value,
                    'roles' => ['customer'],
                    'active_role' => 'customer',
                ],
            );

            Customer::updateOrCreate(
                ['user_id' => (string) $user->_id],
                ['user_id' => (string) $user->_id],
            );

            $this->command->info("Seeded customer: {$user->name}");
        }
    }
}