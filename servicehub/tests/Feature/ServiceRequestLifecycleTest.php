<?php

use App\Enums\ServiceRequestStatus;
use App\Enums\VerificationStatus;
use App\Models\Artisan;
use App\Models\PlatformSetting;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\ServiceRequest;
use App\Models\User;
use App\Services\ServiceRequest\ServiceRequestLifecycleService;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

uses(DatabaseMigrations::class);

function lifecycleCustomer(): User
{
    return User::factory()->create(['roles' => ['customer']]);
}

function lifecycleService(): Service
{
    $category = ServiceCategory::create(['name' => 'Lifecycle '.Str::random(8), 'slug' => 'lifecycle-'.Str::lower(Str::random(8)), 'is_active' => true]);

    return Service::create(['service_category_id' => $category->getKey(), 'name' => 'Lifecycle service', 'slug' => 'lifecycle-service-'.Str::lower(Str::random(8)), 'is_active' => true]);
}

function lifecycleArtisan(Service $service, string $area = 'Douala V'): array
{
    $user = User::factory()->create(['roles' => ['artisan']]);
    $artisan = Artisan::create([
        'user_id' => $user->getKey(),
        'professional_title' => 'Lifecycle artisan',
        'experience_years' => 8,
        'verification_status' => VerificationStatus::VERIFIED,
        'service_areas' => [$area],
        'service_offerings' => [['service_reference' => $service->getKey(), 'is_active' => true]],
        'availability' => ['accepting_requests' => true],
    ]);

    return [$user, $artisan];
}

function lifecycleData(Service $service): array
{
    return ['service_id' => $service->getKey(), 'description' => 'A sufficiently detailed request for deterministic lifecycle testing.', 'location' => ['type' => 'Point', 'coordinates' => [9.7679, 4.0511], 'label' => 'Douala V']];
}

it('submits into selection or recoverable no-artisan states', function () {
    $customer = lifecycleCustomer();
    $service = lifecycleService();
    [, $artisan] = lifecycleArtisan($service);
    $lifecycle = app(ServiceRequestLifecycleService::class);

    $request = $lifecycle->submitNewRequest($customer, lifecycleData($service));
    expect($request->status)->toBe(ServiceRequestStatus::AWAITING_ARTISAN_SELECTION)
        ->and($request->matching_attempts)->toBe(1)
        ->and($request->no_artisan_reason)->toBeNull();

    $empty = $lifecycle->submitNewRequest($customer, lifecycleData(lifecycleService()));
    expect($empty->status)->toBe(ServiceRequestStatus::NO_ARTISAN_AVAILABLE)
        ->and($empty->no_artisan_reason)->not->toBeNull();
});

it('stores the AI-assist flag when submitting a request', function () {
    $customer = lifecycleCustomer();
    $service = lifecycleService();
    $lifecycle = app(ServiceRequestLifecycleService::class);

    $enabled = $lifecycle->submitNewRequest($customer, [
        ...lifecycleData($service),
        'ai_assist_enabled' => true,
    ]);
    $disabled = $lifecycle->submitNewRequest($customer, lifecycleData($service));

    expect($enabled->ai_assist_enabled)->toBeTrue()
        ->and($disabled->ai_assist_enabled)->toBeFalse();
});

it('records selection, approval, decline, and customer change events', function () {
    $customer = lifecycleCustomer();
    $service = lifecycleService();
    [$artisanUser, $artisan] = lifecycleArtisan($service);
    $lifecycle = app(ServiceRequestLifecycleService::class);
    $request = $lifecycle->submitNewRequest($customer, lifecycleData($service));

    $request = $lifecycle->selectArtisan($request, $customer, $artisan->getKey());
    expect($request->status)->toBe(ServiceRequestStatus::PENDING_ARTISAN_RESPONSE)
        ->and($request->selected_artisan_id)->toBe($artisan->getKey())
        ->and($request->pending_since)->not->toBeNull()
        ->and($request->selection_history[0]['event'])->toBe('selected');

    $request = $lifecycle->artisanApproves($request, $artisanUser);
    expect($request->status)->toBe(ServiceRequestStatus::ARTISAN_APPROVED)->and($request->pending_since)->toBeNull();

    $request->update(['status' => ServiceRequestStatus::PENDING_ARTISAN_RESPONSE, 'pending_since' => now()]);
    $request = $lifecycle->artisanDeclines($request, $artisanUser, 'Unavailable this week.');
    expect($request->status)->toBe(ServiceRequestStatus::AWAITING_ARTISAN_SELECTION)
        ->and($request->selected_artisan_id)->toBeNull()
        ->and(collect($request->selection_history)->last()['event'])->toBe('declined');

    $request = $lifecycle->selectArtisan($request, $customer, $artisan->getKey());
    $request = $lifecycle->customerChangesArtisan($request, $customer, 'Prefer another time.');
    expect($request->status)->toBe(ServiceRequestStatus::AWAITING_ARTISAN_SELECTION)
        ->and(collect($request->selection_history)->last()['event'])->toBe('changed_by_customer');
});

it('expires only pending artisan responses and records timeouts', function () {
    $customer = lifecycleCustomer();
    $service = lifecycleService();
    [, $artisan] = lifecycleArtisan($service);
    $request = app(ServiceRequestLifecycleService::class)->selectArtisan(
        app(ServiceRequestLifecycleService::class)->submitNewRequest($customer, lifecycleData($service)), $customer, $artisan->getKey(),
    );
    $request->update(['pending_since' => now()->subHours(25)]);
    PlatformSetting::create(['key' => 'artisan_response_timeout_hours', 'value' => 24]);

    $this->artisan('service-requests:expire-pending-responses')->assertSuccessful();
    expect($request->fresh()->status)->toBe(ServiceRequestStatus::AWAITING_ARTISAN_SELECTION)
        ->and(collect($request->fresh()->selection_history)->last()['event'])->toBe('timeout');
});

it('retries matching and blocks reselection after quotation acceptance', function () {
    $customer = lifecycleCustomer();
    $service = lifecycleService();
    $lifecycle = app(ServiceRequestLifecycleService::class);
    $request = $lifecycle->submitNewRequest($customer, lifecycleData($service));
    expect($request->status)->toBe(ServiceRequestStatus::NO_ARTISAN_AVAILABLE);
    [, $artisan] = lifecycleArtisan($service);

    $request = $lifecycle->retryMatching($request, $customer);
    expect($request->status)->toBe(ServiceRequestStatus::AWAITING_ARTISAN_SELECTION)
        ->and($request->matching_attempts)->toBe(2)
        ->and($request->no_artisan_reason)->toBeNull();

    $request->update(['status' => ServiceRequestStatus::QUOTATION_ACCEPTED]);
    expect(fn () => $lifecycle->selectArtisan($request, $customer, $artisan->getKey()))->toThrow(ValidationException::class)
        ->and(fn () => $lifecycle->customerChangesArtisan($request, $customer))->toThrow(ValidationException::class);
});

it('rejects a duplicate selection while the artisan response is pending', function () {
    $customer = lifecycleCustomer();
    $service = lifecycleService();
    [, $artisan] = lifecycleArtisan($service);
    $lifecycle = app(ServiceRequestLifecycleService::class);
    $request = $lifecycle->selectArtisan(
        $lifecycle->submitNewRequest($customer, lifecycleData($service)),
        $customer,
        $artisan->getKey(),
    );

    expect(fn () => $lifecycle->selectArtisan($request, $customer, $artisan->getKey()))
        ->toThrow(ValidationException::class);
});

it('hides a selected request from every other artisan', function () {
    $customer = lifecycleCustomer();
    $service = lifecycleService();
    [, $selected] = lifecycleArtisan($service);
    [$otherUser] = lifecycleArtisan($service);
    $request = app(ServiceRequestLifecycleService::class)->selectArtisan(
        app(ServiceRequestLifecycleService::class)->submitNewRequest($customer, lifecycleData($service)), $customer, $selected->getKey(),
    );

    $this->actingAs($otherUser, 'sanctum')->postJson("/api/artisan/service-requests/{$request->getKey()}/approve")->assertNotFound();
    $this->actingAs($otherUser, 'sanctum')->postJson("/api/artisan/service-requests/{$request->getKey()}/decline")->assertNotFound();
});
