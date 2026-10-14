<?php

use App\Enums\ServiceRequestStatus;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

function materialsFixture(): array
{
    [$customer, $artisan, $request] = selectedRequestFixture();
    $request->update([
        'status' => ServiceRequestStatus::PAYMENT_PENDING,
        'quotation' => ['status' => 'accepted', 'labor_amount' => 15000, 'currency' => 'XAF'],
    ]);

    return [$customer, $artisan, $request];
}

function proposedMaterials(): array
{
    return [
        'materials' => [
            ['name' => 'PVC pipe', 'quantity' => 2, 'unit' => 'metre', 'unit_cost' => 2500],
            ['name' => 'Pipe connector', 'quantity' => 3, 'unit' => 'piece', 'unit_cost' => 500],
        ],
    ];
}

it('allows only the selected artisan to propose job-specific materials after quotation acceptance', function () {
    [$customer, $artisan, $request] = materialsFixture();

    $this->actingAs($artisan, 'sanctum')
        ->postJson("/api/artisan/service-requests/{$request->getKey()}/materials", proposedMaterials())
        ->assertOk()
        ->assertJsonPath('service_request.materials.0.estimated_cost', 5000)
        ->assertJsonPath('service_request.materials.0.approval_status', 'proposed')
        ->assertJsonPath('service_request.status', ServiceRequestStatus::PAYMENT_PENDING->value);

    $this->actingAs($customer, 'sanctum')
        ->postJson("/api/artisan/service-requests/{$request->getKey()}/materials", proposedMaterials())
        ->assertForbidden();
});

it('requires the customer to approve the exact proposed material cost', function () {
    [$customer, $artisan, $request] = materialsFixture();

    $this->actingAs($artisan, 'sanctum')
        ->postJson("/api/artisan/service-requests/{$request->getKey()}/materials", proposedMaterials())
        ->assertOk();

    $this->actingAs($customer, 'sanctum')
        ->postJson("/api/customer/service-requests/{$request->getKey()}/materials/approve", ['approved_total' => 6000])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('approved_total');

    $this->actingAs($customer, 'sanctum')
        ->postJson("/api/customer/service-requests/{$request->getKey()}/materials/approve", ['approved_total' => 6500])
        ->assertOk()
        ->assertJsonPath('service_request.materials.0.approval_status', 'approved')
        ->assertJsonPath('service_request.status_history.1.materials_approval_status', 'approved');
});

it('marks a revised material estimate as requiring additional approval', function () {
    [$customer, $artisan, $request] = materialsFixture();

    $this->actingAs($artisan, 'sanctum')->postJson("/api/artisan/service-requests/{$request->getKey()}/materials", proposedMaterials())->assertOk();
    $this->actingAs($customer, 'sanctum')->postJson("/api/customer/service-requests/{$request->getKey()}/materials/approve", ['approved_total' => 6500])->assertOk();

    $this->actingAs($artisan, 'sanctum')
        ->postJson("/api/artisan/service-requests/{$request->getKey()}/materials", [
            'materials' => [
                ['name' => 'PVC pipe', 'quantity' => 2, 'unit' => 'metre', 'unit_cost' => 3500],
            ],
        ])
        ->assertOk()
        ->assertJsonPath('service_request.materials.0.proposal_version', 2)
        ->assertJsonPath('service_request.materials.0.approval_status', 'proposed');
});
