<?php

use App\Contracts\Payments\CamPayGateway;
use App\Enums\DisputeStatus;
use App\Enums\PaymentStatus;
use App\Enums\PayoutStatus;
use App\Enums\ServiceRequestStatus;
use App\Enums\VerificationStatus;
use App\Models\ArtisanProfile;
use App\Models\AuditLog;
use App\Models\Dispute;
use App\Models\Payment;
use App\Models\Payout;
use App\Models\PlatformNotification;
use App\Models\PlatformSetting;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\ServiceRequest;
use App\Models\User;
use App\Services\DisputeResolutionService;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Str;

uses(DatabaseMigrations::class);

function financialDisputeScenario(float $snapshotRate = 0.07): array
{
    $customer = User::create(['name' => 'Finance Customer', 'email' => 'finance-customer@example.test', 'phone' => '677511111', 'password' => 'A-secure-password1', 'roles' => ['customer']]);
    $artisanUser = User::create(['name' => 'Finance Artisan', 'email' => 'finance-artisan@example.test', 'phone' => '677522222', 'password' => 'A-secure-password1', 'roles' => ['artisan']]);
    $admin = User::create(['name' => 'Finance Admin', 'email' => 'finance-admin@example.test', 'phone' => '677533333', 'password' => 'A-secure-password1', 'roles' => ['admin']]);
    $category = ServiceCategory::create(['name' => 'Finance Category', 'slug' => 'finance-category', 'is_active' => true]);
    $service = Service::create(['service_category_id' => $category->getKey(), 'name' => 'Finance Service', 'slug' => 'finance-service', 'is_active' => true]);
    $artisan = ArtisanProfile::create(['user_id' => $artisanUser->getKey(), 'professional_title' => 'Electrician', 'verification_status' => VerificationStatus::VERIFIED, 'payout_phone' => '237699555555']);
    $request = ServiceRequest::create([
        'customer_id' => $customer->getKey(), 'service_id' => $service->getKey(), 'selected_artisan_id' => $artisan->getKey(),
        'description' => 'Financial dispute test request.', 'location' => ['type' => 'Point', 'coordinates' => [11.5, 3.8]],
        'status' => ServiceRequestStatus::DISPUTED, 'status_history' => [],
    ]);
    $payment = Payment::create([
        'service_request_id' => $request->getKey(), 'customer_id' => $customer->getKey(), 'amount' => 20000,
        'currency' => 'XAF', 'status' => PaymentStatus::HELD, 'provider' => 'campay', 'provider_reference' => 'collection-finance',
        'idempotency_key' => (string) Str::uuid(), 'external_reference' => 'SH-finance', 'events' => [],
        'commission_rate_snapshot' => $snapshotRate, 'commission_amount' => 1400, 'artisan_gross_amount' => 20000, 'artisan_net_amount' => 20000 - (int) round(20000 * $snapshotRate),
    ]);
    $request->update(['payment_id' => $payment->getKey()]);
    $dispute = Dispute::create([
        'service_request_id' => $request->getKey(), 'payment_id' => $payment->getKey(), 'reporter_id' => $customer->getKey(),
        'reporter_role' => 'customer', 'reason' => 'Quality concern', 'description' => 'The service outcome requires a financial review.',
        'evidence' => [], 'updates' => [], 'status' => DisputeStatus::UNDER_REVIEW, 'status_history' => [],
    ]);

    return [$customer, $artisanUser, $admin, $request, $payment, $dispute];
}

function realGatewaySuccessFake(): CamPayGateway
{
    return new class implements CamPayGateway
    {
        public function initiateCollection(int|float $amount, string $phone, string $description, string $externalReference): array
        {
            return ['reference' => 'collection-real', 'status' => 'SUCCESSFUL', 'raw' => ['status' => 'SUCCESSFUL']];
        }

        public function transactionStatus(string $reference): array
        {
            return ['reference' => $reference, 'status' => 'SUCCESSFUL', 'raw' => ['status' => 'SUCCESSFUL']];
        }

        public function initiatePayout(int|float $amount, string $phone, string $description, string $externalReference): array
        {
            return ['reference' => 'payout-real', 'status' => 'SUCCESSFUL', 'raw' => ['status' => 'SUCCESSFUL', 'is_simulated' => false]];
        }

        public function initiateRefund(int|float $amount, string $collectionReference, string $externalReference): array
        {
            throw new RuntimeException('A real CamPay refund is intentionally unsupported.');
        }
    };
}

function campayWebhookSignature(string $secret): string
{
    $header = rtrim(strtr(base64_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT'])), '+/', '-_'), '=');
    $claims = rtrim(strtr(base64_encode(json_encode(['source' => 'campay'])), '+/', '-_'), '=');
    $signature = rtrim(strtr(base64_encode(hash_hmac('sha256', $header.'.'.$claims, $secret, true)), '+/', '-_'), '=');

    return $header.'.'.$claims.'.'.$signature;
}

it('uses the default commission rate and audits an administrator update', function () {
    Cache::forget('platform-settings:commission-rate');
    [, , $admin] = financialDisputeScenario();

    $this->actingAs($admin, 'sanctum')->getJson('/api/admin/settings/commission')
        ->assertOk()->assertJsonPath('commission_rate', 0.07);
    $this->actingAs($admin, 'sanctum')->putJson('/api/admin/settings/commission', ['rate' => 0.12, 'reason' => 'Pilot market adjustment.'])
        ->assertOk()->assertJsonPath('commission_rate', 0.12);

    expect(PlatformSetting::query()->where('key', 'commission_rate')->value('value'))->toBe(0.12)
        ->and(AuditLog::query()->where('event_type', 'platform.commission_rate_updated')->count())->toBe(1);
});

it('rejects commission rates outside the approved range and non-admin updates', function () {
    [$customer, , $admin] = financialDisputeScenario();
    $this->actingAs($customer, 'sanctum')->putJson('/api/admin/settings/commission', ['rate' => 0.07, 'reason' => 'Not authorized request.'])->assertForbidden();
    $this->actingAs($admin, 'sanctum')->putJson('/api/admin/settings/commission', ['rate' => 0.31, 'reason' => 'Outside allowed range.'])->assertUnprocessable();
});

it('executes a full refund through the clearly marked simulated dispute path', function () {
    [, , $admin, , $payment, $dispute] = financialDisputeScenario();
    $reference = (string) Str::uuid();

    $this->actingAs($admin, 'sanctum')->postJson("/api/admin/disputes/{$dispute->getKey()}/resolve", [
        'decision' => 'refund_customer', 'customer_refund_amount' => 20000, 'artisan_gross_release' => 0,
        'reason' => 'Service was not delivered.', 'resolution_reference' => $reference,
    ])->assertOk()->assertJsonPath('dispute.status', DisputeStatus::PENDING_EXECUTION->value);
    $this->actingAs($admin, 'sanctum')->getJson("/api/admin/disputes/{$dispute->getKey()}")
        ->assertOk()
        ->assertJsonPath('simulation_notice', 'SIMULATED — no real funds moved.')
        ->assertJsonMissingPath('payment.phone');
    $this->actingAs($admin, 'sanctum')->postJson("/api/admin/disputes/{$dispute->getKey()}/confirm-resolution")
        ->assertOk()->assertJsonPath('dispute.status', DisputeStatus::RESOLVED->value);

    expect($payment->fresh()->status)->toBe(PaymentStatus::REFUNDED)
        ->and(collect($payment->fresh()->events)->contains(fn (array $event) => ($event['is_simulated'] ?? false) === true))->toBeTrue()
        ->and(AuditLog::query()->where('event_type', 'dispute.resolution_executed')->count())->toBe(1)
        ->and(PlatformNotification::query()->where('type', 'dispute_resolution_completed')->count())->toBe(2);
});

it('uses the payment snapshot rather than the current commission rate for a real full release', function () {
    [, , $admin, , $payment, $dispute] = financialDisputeScenario(0.05);
    PlatformSetting::create(['key' => 'commission_rate', 'value' => 0.30, 'description' => 'New rate']);
    $this->app->instance(CamPayGateway::class, realGatewaySuccessFake());
    $reference = (string) Str::uuid();

    $this->actingAs($admin, 'sanctum')->postJson("/api/admin/disputes/{$dispute->getKey()}/resolve", [
        'decision' => 'release_artisan', 'customer_refund_amount' => 0, 'artisan_gross_release' => 20000,
        'reason' => 'Service delivery was verified.', 'resolution_reference' => $reference,
    ])->assertOk();
    $this->actingAs($admin, 'sanctum')->postJson("/api/admin/disputes/{$dispute->getKey()}/confirm-resolution")->assertOk();

    expect($payment->fresh()->status)->toBe(PaymentStatus::RELEASED)
        ->and((float) Payout::firstOrFail()->gross_amount)->toBe(20000.0)
        ->and((float) Payout::firstOrFail()->commission_amount)->toBe(1000.0)
        ->and((float) Payout::firstOrFail()->amount)->toBe(19000.0);
});

it('rejects unbalanced split amounts and duplicate resolution references', function () {
    [, , $admin, , , $dispute] = financialDisputeScenario();
    $reference = (string) Str::uuid();
    $this->actingAs($admin, 'sanctum')->postJson("/api/admin/disputes/{$dispute->getKey()}/resolve", [
        'decision' => 'split_resolution', 'customer_refund_amount' => 7000, 'artisan_gross_release' => 12000,
        'reason' => 'Amounts do not balance.', 'resolution_reference' => $reference,
    ])->assertUnprocessable();
    $this->actingAs($admin, 'sanctum')->postJson("/api/admin/disputes/{$dispute->getKey()}/resolve", [
        'decision' => 'split_resolution', 'customer_refund_amount' => 7000, 'artisan_gross_release' => 13000,
        'reason' => 'Amounts balance exactly.', 'resolution_reference' => $reference,
    ])->assertOk();
    $dispute->refresh()->update(['status' => DisputeStatus::UNDER_REVIEW, 'pending_resolution' => null]);
    $this->actingAs($admin, 'sanctum')->postJson("/api/admin/disputes/{$dispute->getKey()}/resolve", [
        'decision' => 'split_resolution', 'customer_refund_amount' => 7000, 'artisan_gross_release' => 13000,
        'reason' => 'Duplicate reference attempt.', 'resolution_reference' => $reference,
    ])->assertUnprocessable()->assertJsonValidationErrors('resolution_reference');
});

it('rejects unauthorized, negative, and non-held financial resolutions', function () {
    [$customer, , $admin, , $payment, $dispute] = financialDisputeScenario();
    $payload = [
        'decision' => 'refund_customer', 'customer_refund_amount' => 20000, 'artisan_gross_release' => 0,
        'reason' => 'The service was not delivered.', 'resolution_reference' => (string) Str::uuid(),
    ];
    $this->actingAs($customer, 'sanctum')->postJson("/api/admin/disputes/{$dispute->getKey()}/resolve", $payload)->assertForbidden();
    $payload['customer_refund_amount'] = -1;
    $payload['resolution_reference'] = (string) Str::uuid();
    $this->actingAs($admin, 'sanctum')->postJson("/api/admin/disputes/{$dispute->getKey()}/resolve", $payload)->assertUnprocessable();
    $payment->update(['status' => PaymentStatus::RELEASED]);
    $payload['customer_refund_amount'] = 20000;
    $payload['resolution_reference'] = (string) Str::uuid();
    $this->actingAs($admin, 'sanctum')->postJson("/api/admin/disputes/{$dispute->getKey()}/resolve", $payload)->assertUnprocessable()->assertJsonValidationErrors('payment');
});

it('requires reconciliation instead of claiming funds returned after simulated split partial execution', function () {
    [, , $admin, , $payment, $dispute] = financialDisputeScenario();
    Config::set('services.campay.simulation_fail_on', 'disburse');
    $reference = (string) Str::uuid();
    $this->actingAs($admin, 'sanctum')->postJson("/api/admin/disputes/{$dispute->getKey()}/resolve", [
        'decision' => 'split_resolution', 'customer_refund_amount' => 5000, 'artisan_gross_release' => 15000,
        'reason' => 'Partial refund with artisan release.', 'resolution_reference' => $reference,
    ])->assertOk();
    $this->actingAs($admin, 'sanctum')->postJson("/api/admin/disputes/{$dispute->getKey()}/confirm-resolution")
        ->assertOk()->assertJsonPath('dispute.status', DisputeStatus::RECONCILIATION_REQUIRED->value);

    expect($payment->fresh()->status)->toBe(PaymentStatus::RECONCILIATION_REQUIRED)
        ->and(Payout::firstOrFail()->status)->toBe(PayoutStatus::FAILED)
        ->and(PlatformNotification::query()->where('type', 'dispute_reconciliation_required')->count())->toBe(1);
});

it('expires an unconfirmed resolution back to review', function () {
    [, , $admin, , , $dispute] = financialDisputeScenario();
    $this->actingAs($admin, 'sanctum')->postJson("/api/admin/disputes/{$dispute->getKey()}/resolve", [
        'decision' => 'refund_customer', 'customer_refund_amount' => 20000, 'artisan_gross_release' => 0,
        'reason' => 'Resolution requires confirmation.', 'resolution_reference' => (string) Str::uuid(),
    ])->assertOk();
    $dispute->refresh()->update(['pending_resolution' => [...$dispute->pending_resolution, 'expires_at' => now()->subMinute()]]);

    expect(app(DisputeResolutionService::class)->expireDueResolutions())->toBe(1)
        ->and($dispute->fresh()->status)->toBe(DisputeStatus::UNDER_REVIEW);
});

it('accepts only a verified CamPay webhook and leaves a pending payment pending', function () {
    [, , , , $payment] = financialDisputeScenario();
    $payment->update(['status' => PaymentStatus::PROCESSING]);
    Config::set('services.campay.webhook_secret', 'webhook-test-secret');

    $payload = ['reference' => 'collection-finance', 'status' => 'PENDING', 'external_reference' => 'SH-finance', 'amount' => 20000, 'currency' => 'XAF'];
    $this->postJson('/api/webhooks/campay', [...$payload, 'signature' => campayWebhookSignature('webhook-test-secret')])
        ->assertOk()->assertJsonPath('payment_found', true);
    expect($payment->fresh()->status)->toBe(PaymentStatus::PROCESSING)
        ->and(AuditLog::query()->where('event_type', 'payment.provider_webhook_received')->count())->toBe(1);
    $this->postJson('/api/webhooks/campay', [...$payload, 'signature' => 'invalid'])
        ->assertUnauthorized();
});

it('reconciles a pending real payout through a verified CamPay webhook', function () {
    [, , , $request, $payment] = financialDisputeScenario();
    $payment->update(['status' => PaymentStatus::RELEASING]);
    $payout = Payout::create([
        'payment_id' => $payment->getKey(), 'service_request_id' => $request->getKey(), 'artisan_profile_id' => $request->selected_artisan_id,
        'amount' => 18600, 'currency' => 'XAF', 'status' => PayoutStatus::PROCESSING, 'provider' => 'campay',
        'provider_reference' => 'payout-webhook', 'external_reference' => 'SH-payout-webhook', 'events' => [],
    ]);
    Config::set('services.campay.webhook_secret', 'webhook-test-secret');

    $this->postJson('/api/webhooks/campay', ['reference' => 'payout-webhook', 'status' => 'SUCCESSFUL', 'external_reference' => 'SH-payout-webhook', 'amount' => 18600, 'currency' => 'XAF', 'signature' => campayWebhookSignature('webhook-test-secret')])
        ->assertOk()->assertJsonPath('payout_found', true);
    expect($payout->fresh()->status)->toBe(PayoutStatus::PAID)
        ->and($payment->fresh()->status)->toBe(PaymentStatus::RELEASED)
        ->and(AuditLog::query()->where('event_type', 'payout.provider_webhook_received')->count())->toBe(1);
});

it('rejects a signed CamPay webhook whose payment details do not match', function () {
    [, , , , $payment] = financialDisputeScenario();
    $payment->update(['status' => PaymentStatus::PROCESSING]);
    Config::set('services.campay.webhook_secret', 'webhook-test-secret');

    $this->postJson('/api/webhooks/campay', [
        'reference' => 'collection-finance', 'status' => 'SUCCESSFUL', 'external_reference' => 'wrong-reference',
        'amount' => 20000, 'currency' => 'XAF', 'signature' => campayWebhookSignature('webhook-test-secret'),
    ])->assertUnprocessable()->assertJsonValidationErrors('webhook');
    expect($payment->fresh()->status)->toBe(PaymentStatus::PROCESSING);
});
