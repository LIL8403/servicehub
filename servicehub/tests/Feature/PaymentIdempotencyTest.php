<?php

use App\Contracts\Payments\CamPayGateway;
use App\Enums\ServiceRequestStatus;
use App\Models\Payment;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Support\Str;

test('same idempotency key returns same payment', function () {
    $user = User::factory()->create();
    $user->assignRole('customer');
    $user->forceFill(['email_verified_at' => now()])->save();

    $serviceRequest = ServiceRequest::factory()->create([
        'customer_id' => $user->getKey(),
        'status' => ServiceRequestStatus::PAYMENT_PENDING,
        'quotation' => ['labor_amount' => 10000],
    ]);

    $this->app->instance(CamPayGateway::class, new class implements CamPayGateway
    {
        public function initiateCollection(int|float $amount, string $phone, string $description, string $externalReference): array
        {
            return ['reference' => 'idempotency-payment', 'status' => 'PENDING', 'raw' => []];
        }

        public function transactionStatus(string $reference): array
        {
            return ['reference' => $reference, 'status' => 'PENDING', 'raw' => []];
        }

        public function initiatePayout(int|float $amount, string $phone, string $description, string $externalReference): array
        {
            return ['reference' => 'unused', 'status' => 'PENDING', 'raw' => []];
        }

        public function initiateRefund(int|float $amount, string $collectionReference, string $externalReference): array
        {
            return ['reference' => 'unused', 'status' => 'PENDING', 'raw' => []];
        }
    });

    $key = Str::uuid()->toString();

    $response1 = $this->actingAs($user)->postJson("/api/customer/service-requests/{$serviceRequest->getKey()}/payments", [
        'phone' => '237600000000',
        'idempotency_key' => $key,
    ]);

    $response2 = $this->actingAs($user)->postJson("/api/customer/service-requests/{$serviceRequest->getKey()}/payments", [
        'phone' => '237600000000',
        'idempotency_key' => $key,
    ]);

    expect(Payment::count())->toBe(1);
    expect($response1->json('payment.id'))->toBe($response2->json('payment.id'));
});
