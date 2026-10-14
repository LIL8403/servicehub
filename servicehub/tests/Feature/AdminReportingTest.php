<?php

use App\Enums\DisputeStatus;
use App\Enums\PaymentStatus;
use App\Enums\PayoutStatus;
use App\Models\AuditLog;
use App\Models\Dispute;
use App\Models\Payment;
use App\Models\Payout;
use App\Models\User;
use App\Services\AuditLogService;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Support\Str;

uses(DatabaseMigrations::class);

function reportingUser(string $role, string $email): User
{
    return User::create([
        'name' => ucfirst($role).' Reporting User',
        'email' => $email,
        'phone' => '677'.random_int(100000, 999999),
        'password' => 'A-secure-password1',
        'roles' => [$role],
    ]);
}

function reportingPayment(User $customer): Payment
{
    return Payment::create([
        'service_request_id' => 'report-request-'.uniqid(),
        'customer_id' => $customer->getKey(),
        'amount' => 25000,
        'currency' => 'XAF',
        'status' => PaymentStatus::HELD,
        'provider' => 'campay',
        'provider_reference' => 'report-collection-'.uniqid(),
        'idempotency_key' => (string) Str::uuid(),
        'external_reference' => 'SH-report-'.Str::uuid(),
        'phone' => '237677123456',
        'events' => [['status' => 'held', 'from' => '237677123456']],
        'commission_rate_snapshot' => 0.07,
        'commission_amount' => 1750,
        'artisan_gross_amount' => 25000,
        'artisan_net_amount' => 23250,
    ]);
}

it('provides administrators with safe dashboard and transaction oversight data', function () {
    $admin = reportingUser('admin', 'reports-admin@example.test');
    $customer = reportingUser('customer', 'reports-customer@example.test');
    $payment = reportingPayment($customer);
    $payout = Payout::create([
        'payment_id' => $payment->getKey(),
        'service_request_id' => $payment->service_request_id,
        'artisan_profile_id' => 'report-artisan-profile',
        'amount' => 23250,
        'gross_amount' => 25000,
        'commission_amount' => 1750,
        'currency' => 'XAF',
        'status' => PayoutStatus::PAID,
        'provider' => 'campay',
        'provider_reference' => 'report-payout-'.uniqid(),
        'external_reference' => 'SH-payout-'.Str::uuid(),
        'events' => [['status' => 'paid', 'to' => '237699123456']],
    ]);
    Dispute::create([
        'service_request_id' => $payment->service_request_id,
        'payment_id' => $payment->getKey(),
        'reporter_id' => $customer->getKey(),
        'reporter_role' => 'customer',
        'reason' => 'Reporting scenario',
        'description' => 'An administrator needs this dispute in reporting totals.',
        'evidence' => [], 'updates' => [], 'status' => DisputeStatus::OPENED, 'status_history' => [],
    ]);

    $this->actingAs($admin, 'sanctum')->getJson('/api/admin/dashboard')
        ->assertOk()
        ->assertJsonPath('dashboard.users.total', 2)
        ->assertJsonPath('dashboard.payments.by_status.held', 1)
        ->assertJsonPath('dashboard.payouts.by_status.paid', 1)
        ->assertJsonPath('dashboard.disputes.by_status.opened', 1);

    $this->actingAs($admin, 'sanctum')->getJson('/api/admin/payments?status=held')
        ->assertOk()
        ->assertJsonCount(1, 'payments')
        ->assertJsonPath('payments.0.id', $payment->getKey())
        ->assertJsonPath('payments.0.amount', 25000)
        ->assertJsonMissingPath('payments.0.phone')
        ->assertJsonMissingPath('payments.0.events');

    $this->actingAs($admin, 'sanctum')->getJson('/api/admin/payouts?status=paid')
        ->assertOk()
        ->assertJsonCount(1, 'payouts')
        ->assertJsonPath('payouts.0.id', $payout->getKey())
        ->assertJsonMissingPath('payouts.0.events');
});

it('redacts sensitive audit metadata on write and when rendering legacy records', function () {
    $admin = reportingUser('admin', 'audit-admin@example.test');
    $audit = app(AuditLogService::class)->record('payment.collection_attempted', $admin->getKey(), 'payment', 'audit-payment', [
        'phone' => '237677123456',
        'provider_response' => ['from' => '237677123456', 'reference' => 'safe-reference'],
        'amount' => 25000,
    ]);
    AuditLog::create([
        'event_type' => 'legacy.payment.event', 'actor_id' => $admin->getKey(), 'subject_type' => 'payment', 'subject_id' => 'legacy-payment',
        'metadata' => ['phone' => '237699999999', 'provider_response' => ['to' => '237699999999', 'reference' => 'legacy-reference']],
        'expires_at' => now()->addYear(),
    ]);

    expect($audit->metadata)->toBe([
        'provider_response' => ['reference' => 'safe-reference'],
        'amount' => 25000,
    ]);

    $this->actingAs($admin, 'sanctum')->getJson('/api/admin/audit-logs?subject_id=legacy-payment')
        ->assertOk()
        ->assertJsonPath('audit_logs.0.subject_id', 'legacy-payment')
        ->assertJsonPath('audit_logs.0.metadata.provider_response.reference', 'legacy-reference')
        ->assertJsonMissingPath('audit_logs.0.metadata.phone')
        ->assertJsonMissingPath('audit_logs.0.metadata.provider_response.to');
});

it('keeps reporting endpoints restricted to administrators', function () {
    $customer = reportingUser('customer', 'reports-forbidden@example.test');

    $this->actingAs($customer, 'sanctum')->getJson('/api/admin/dashboard')->assertForbidden();
    $this->actingAs($customer, 'sanctum')->getJson('/api/admin/payments')->assertForbidden();
    $this->actingAs($customer, 'sanctum')->getJson('/api/admin/audit-logs')->assertForbidden();
});
