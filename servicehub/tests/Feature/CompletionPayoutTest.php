<?php

use App\Contracts\Payments\CamPayGateway;
use App\Enums\PaymentStatus;
use App\Enums\PayoutStatus;
use App\Enums\ServiceRequestStatus;
use App\Models\ArtisanProfile;
use App\Models\AuditLog;
use App\Models\Payment;
use App\Models\Payout;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

it('books a verified payment then releases one payout after customer completion confirmation', function () {
    [$customer, $artisan, $request] = materialsFixture();
    $customer->forceFill(['email_verified_at' => now()])->save();
    $artisan->artisanProfile->update(['payout_phone' => '237699123456']);
    $request->update(['materials' => [['estimated_cost' => 6500, 'approval_status' => 'approved']]]);

    $this->app->instance(CamPayGateway::class, new class implements CamPayGateway
    {
        public function initiateCollection(int|float $amount, string $phone, string $description, string $externalReference): array
        {
            return ['reference' => 'collection-1', 'status' => 'SUCCESSFUL', 'raw' => ['status' => 'SUCCESSFUL']];
        }

        public function transactionStatus(string $reference): array
        {
            return ['reference' => $reference, 'status' => 'SUCCESSFUL', 'raw' => ['status' => 'SUCCESSFUL']];
        }

        public function initiatePayout(int|float $amount, string $phone, string $description, string $externalReference): array
        {
            expect($amount)->toBe(19995.0)->and($phone)->toBe('237699123456');

            return ['reference' => 'payout-1', 'status' => 'SUCCESSFUL', 'raw' => ['status' => 'SUCCESSFUL']];
        }

        public function initiateRefund(int|float $amount, string $collectionReference, string $externalReference): array
        {
            return ['reference' => 'refund-1', 'status' => 'SUCCESSFUL', 'raw' => ['status' => 'SUCCESSFUL']];
        }
    });

    $this->actingAs($customer, 'sanctum')->postJson("/api/customer/service-requests/{$request->getKey()}/payments", [
        'phone' => '237677123456', 'idempotency_key' => '4d327a96-fc83-4530-8ff9-95bbd89b7b01',
    ])->assertCreated()->assertJsonPath('payment.status', PaymentStatus::HELD->value);

    expect($request->fresh()->status)->toBe(ServiceRequestStatus::BOOKED);

    $this->actingAs($artisan, 'sanctum')->postJson("/api/artisan/service-requests/{$request->getKey()}/start")
        ->assertOk()->assertJsonPath('service_request.status', ServiceRequestStatus::IN_PROGRESS->value);
    $this->actingAs($artisan, 'sanctum')->postJson("/api/artisan/service-requests/{$request->getKey()}/completion", ['notes' => 'Work completed.'])
        ->assertOk()->assertJsonPath('service_request.status', ServiceRequestStatus::AWAITING_CONFIRMATION->value);

    expect(Payment::firstOrFail()->status)->toBe(PaymentStatus::HELD);
    expect((string) Payment::firstOrFail()->service_request_id)->toBe($request->getKey());
    expect((string) Payment::firstOrFail()->customer_id)->toBe($customer->getKey());
    expect(Payment::query()->get())->toHaveCount(1);
    expect($request->fresh()->payment_id)->toBe(Payment::firstOrFail()->getKey());

    $this->actingAs($customer, 'sanctum')->postJson("/api/customer/service-requests/{$request->getKey()}/completion/confirm")
        ->assertOk()
        ->assertJsonPath('service_request.status', ServiceRequestStatus::COMPLETED->value)
        ->assertJsonPath('payout.status', PayoutStatus::PAID->value)
        ->assertJsonPath('payout.amount', 19995);

    expect(Payout::count())->toBe(1);
    expect(Payment::firstOrFail()->status)->toBe(PaymentStatus::RELEASED);
    expect(AuditLog::query()->where('event_type', 'payment.payout_attempted')->count())->toBe(1);

    $this->actingAs($customer, 'sanctum')->postJson("/api/customer/service-requests/{$request->getKey()}/payout/retry")
        ->assertOk()->assertJsonPath('payout.id', Payout::firstOrFail()->getKey());
    expect(Payout::count())->toBe(1);
});

it('does not allow an artisan other than the selected artisan to start a booked request', function () {
    [$customer, , $request] = materialsFixture();
    $request->update(['status' => ServiceRequestStatus::BOOKED]);
    $other = User::factory()->create(['roles' => ['artisan']]);
    ArtisanProfile::create(['user_id' => $other->getKey(), 'verification_status' => 'verified']);

    $this->actingAs($other, 'sanctum')->postJson("/api/artisan/service-requests/{$request->getKey()}/start")
        ->assertNotFound();
});
