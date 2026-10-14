<?php

use App\Ai\Agents\ArtisanRecommender;
use App\Enums\ServiceRequestStatus;
use App\Enums\VerificationStatus;
use App\Models\Artisan;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\User;
use App\Services\ServiceRequest\ServiceRequestLifecycleService;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Support\Str;

uses(DatabaseMigrations::class);

function aiRankingCustomer(): User
{
    return User::factory()->create(['roles' => ['customer']]);
}

function aiRankingService(): Service
{
    $suffix = Str::lower(Str::random(8));
    $category = ServiceCategory::create(['name' => "AI {$suffix}", 'slug' => "ai-{$suffix}", 'is_active' => true]);

    return Service::create(['service_category_id' => $category->getKey(), 'name' => "AI service {$suffix}", 'slug' => "ai-service-{$suffix}", 'is_active' => true]);
}

function aiRankingArtisan(Service $service, int $experience = 5): Artisan
{
    $user = User::factory()->create(['roles' => ['artisan']]);

    return Artisan::create([
        'user_id' => $user->getKey(),
        'professional_title' => 'Verified specialist',
        'experience_years' => $experience,
        'verification_status' => VerificationStatus::VERIFIED,
        'service_areas' => ['Douala V'],
        'service_offerings' => [['service_reference' => $service->getKey(), 'is_active' => true]],
        'availability' => ['accepting_requests' => true],
    ]);
}

function aiRankingData(Service $service, bool $enabled = true): array
{
    return [
        'service_id' => $service->getKey(),
        'description' => 'A detailed plumbing request that needs a verified specialist.',
        'location' => ['type' => 'Point', 'coordinates' => [9.7679, 4.0511], 'label' => 'Douala V'],
        'ai_assist_enabled' => $enabled,
    ];
}

beforeEach(function () {
    config()->set('ai.default', 'openai');
    config()->set('ai.providers.openai.key', 'test-key');
});

it('stores valid AI rankings when AI assist is enabled', function () {
    $customer = aiRankingCustomer();
    $service = aiRankingService();
    $artisan = aiRankingArtisan($service);
    ArtisanRecommender::fake([['recommendations' => [[
        'artisan_id' => $artisan->getKey(), 'confidence_score' => 98, 'reason' => 'Excellent local fit.',
    ]]]]);

    $request = app(ServiceRequestLifecycleService::class)->submitNewRequest($customer, aiRankingData($service));

    expect($request->recommendation['artisan_rankings'][0])->toMatchArray([
        'artisan_id' => $artisan->getKey(), 'match_score' => 98, 'reason' => 'Excellent local fit.',
    ])->and(collect($request->status_history)->pluck('event'))->toContain('ai_ranked');
});

it('records an empty ranking without changing the request lifecycle', function () {
    $customer = aiRankingCustomer();
    $service = aiRankingService();
    aiRankingArtisan($service);
    ArtisanRecommender::fake([['recommendations' => []]]);

    $request = app(ServiceRequestLifecycleService::class)->submitNewRequest($customer, aiRankingData($service));

    expect($request->recommendation)->toBeNull()
        ->and($request->status)->toBe(ServiceRequestStatus::AWAITING_ARTISAN_SELECTION)
        ->and(collect($request->status_history)->pluck('event'))->toContain('ai_ranking_empty');
});

it('keeps the request usable when AI ranking fails or is disabled', function () {
    $customer = aiRankingCustomer();
    $service = aiRankingService();
    aiRankingArtisan($service);
    ArtisanRecommender::fake([fn () => throw new RuntimeException('AI unavailable')]);

    $failed = app(ServiceRequestLifecycleService::class)->submitNewRequest($customer, aiRankingData($service));
    $disabled = app(ServiceRequestLifecycleService::class)->submitNewRequest($customer, aiRankingData($service, false));

    expect($failed->status)->toBe(ServiceRequestStatus::AWAITING_ARTISAN_SELECTION)
        ->and(collect($failed->status_history)->pluck('event'))->not->toContain('ai_ranked')
        ->and($disabled->recommendation)->toBeNull();
});

it('sanitizes, sorts, caps rankings, and exposes stored recommendations', function () {
    $customer = aiRankingCustomer();
    $service = aiRankingService();
    $artisans = collect(range(1, 4))->map(fn (int $experience) => aiRankingArtisan($service, $experience));
    ArtisanRecommender::fake([['recommendations' => [
        ['artisan_id' => 'unknown', 'confidence_score' => 100, 'reason' => 'Ignored'],
        ['artisan_id' => $artisans[0]->getKey(), 'confidence_score' => 40, 'reason' => 'First'],
        ['artisan_id' => $artisans[1]->getKey(), 'confidence_score' => 95, 'reason' => 'Second'],
        ['artisan_id' => $artisans[2]->getKey(), 'confidence_score' => 80, 'reason' => 'Third'],
        ['artisan_id' => $artisans[3]->getKey(), 'confidence_score' => 70, 'reason' => 'Fourth'],
    ]]]);

    $request = app(ServiceRequestLifecycleService::class)->submitNewRequest($customer, aiRankingData($service));
    $rankings = $request->recommendation['artisan_rankings'];

    expect($rankings)->toHaveCount(3)
        ->and(array_column($rankings, 'match_score'))->toBe([95, 80, 70]);

    $this->actingAs($customer, 'sanctum')
        ->getJson("/api/customer/service-requests/{$request->getKey()}/eligible-artisans")
        ->assertOk()
        ->assertJsonPath('request.ai_recommendations_available', true)
        ->assertJsonCount(3, 'ai_recommendations');
});

it('returns an empty recommendation array when none was stored', function () {
    $customer = aiRankingCustomer();
    $service = aiRankingService();
    aiRankingArtisan($service);
    $request = app(ServiceRequestLifecycleService::class)->submitNewRequest($customer, aiRankingData($service, false));

    $this->actingAs($customer, 'sanctum')
        ->getJson("/api/customer/service-requests/{$request->getKey()}/eligible-artisans")
        ->assertOk()
        ->assertJsonPath('request.ai_recommendations_available', false)
        ->assertJsonCount(0, 'ai_recommendations');
});
