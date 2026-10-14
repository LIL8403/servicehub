<?php

namespace Database\Factories;

use App\Enums\ServiceRequestStatus;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ServiceRequestFactory extends Factory
{
    protected $model = ServiceRequest::class;

    public function definition(): array
    {
        return [
            'customer_id' => User::factory(),
            'service_id' => 'service-' . $this->faker->uuid(),
            'description' => $this->faker->sentence(),
            'status' => ServiceRequestStatus::CREATED,
            'status_history' => [],
        ];
    }
}
