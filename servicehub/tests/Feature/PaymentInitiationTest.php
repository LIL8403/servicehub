<?php

use App\Contracts\Payments\CamPayGateway;
use App\Enums\PaymentStatus;
use App\Models\AuditLog;
use App\Models\Payment;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

function paymentFixture(): array
{
    [$customer, , $request] = materialsFixture();
    $request->update(['materials' => [['estimated_cost' => 6500, 'approval_status' => 'approved']]]);

    return [$customer, $request];
}

it('initiates a server-side CamPay collection once per customer idempotency key', function () {
    [$customer, $request] = paymentFixture();
    $customer->forceFill(['email_verified_at' => now()])->save();
    $this->app->instance(CamPayGateway::class, new class implements CamPayGateway
    {
        public function initiateCollection(int|float $amount, string $phone, string $description, string $externalReference): array
        {
            return ['reference' => 'campay-ref-1', 'status' => 'PENDING', 'raw' => ['reference' => 'campay-ref-1', 'status' => 'PENDING']];
        }

        public function transactionStatus(string $reference): array
        {
            return ['reference' => $reference, 'status' => 'SUCCESSFUL', 'raw' => ['status' => 'SUCCESSFUL']];
        }

        public function initiatePayout(int|float $amount, string $phone, string $description, string $externalReference): array
        {
            return ['reference' => 'campay-payout-ref-1', 'status' => 'SUCCESSFUL', 'raw' => ['status' => 'SUCCESSFUL']];
        }

        public function initiateRefund(int|float $amount, string $collectionReference, string $externalReference): array
        {
            return ['reference' => 'campay-refund-ref-1', 'status' => 'SUCCESSFUL', 'raw' => ['status' => 'SUCCESSFUL']];
        }
    });
    $key = 'c6799f37-f086-4f4e-a753-846b8f1ca8d9';

    $response = $this->actingAs($customer, 'sanctum')->postJson("/api/customer/service-requests/{$request->getKey()}/payments", ['phone' => '237677123456', 'idempotency_key' => $key]);
    $response->assertCreated()->assertJsonPath('payment.status', PaymentStatus::PROCESSING->value)->assertJsonPath('payment.amount', 21500);
    expect(Payment::firstOrFail()->commission_rate_snapshot)->toBe(0.07)
        ->and(Payment::firstOrFail()->commission_amount)->toBe(1505.0)
        ->and(Payment::firstOrFail()->artisan_net_amount)->toBe(19995.0)
        ->and(AuditLog::query()->where('event_type', 'payment.collection_attempted')->count())->toBe(1);

    $this->actingAs($customer, 'sanctum')->postJson("/api/customer/service-requests/{$request->getKey()}/payments", ['phone' => '237677123456', 'idempotency_key' => $key])
        ->assertCreated()->assertJsonPath('payment.id', $response->json('payment.id'));
    expect(Payment::count())->toBe(1);
});
