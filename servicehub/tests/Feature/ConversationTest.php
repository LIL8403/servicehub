<?php

use App\Enums\ServiceRequestStatus;
use App\Enums\VerificationStatus;
use App\Models\ArtisanProfile;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

uses(DatabaseMigrations::class);

function conversationScenario(): array
{
    $customer = User::create(['name' => 'Conversation Customer', 'email' => 'conversation-customer@example.test', 'phone' => '677555555', 'password' => 'A-secure-password1', 'roles' => ['customer']]);
    $artisanUser = User::create(['name' => 'Conversation Artisan', 'email' => 'conversation-artisan@example.test', 'phone' => '677666666', 'password' => 'A-secure-password1', 'roles' => ['artisan']]);
    $category = ServiceCategory::create(['name' => 'Conversation Category', 'slug' => 'conversation-category', 'is_active' => true]);
    $service = Service::create(['service_category_id' => $category->getKey(), 'name' => 'Conversation Service', 'slug' => 'conversation-service', 'is_active' => true]);
    $artisan = ArtisanProfile::create(['user_id' => $artisanUser->getKey(), 'professional_title' => 'Plumber', 'verification_status' => VerificationStatus::VERIFIED]);
    $request = ServiceRequest::create([
        'customer_id' => $customer->getKey(), 'service_id' => $service->getKey(), 'selected_artisan_id' => $artisan->getKey(),
        'description' => 'Repair discussion.', 'location' => ['type' => 'Point', 'coordinates' => [11.5, 3.8]],
        'status' => ServiceRequestStatus::PENDING_ARTISAN_RESPONSE, 'status_history' => [],
    ]);

    return [$customer, $artisanUser, $request];
}

it('creates a request-associated conversation and restricts messages to its participants', function () {
    [$customer, $artisan, $request] = conversationScenario();
    $conversationResponse = $this->actingAs($customer, 'sanctum')->getJson("/api/customer/service-requests/{$request->getKey()}/conversation")
        ->assertOk()->assertJsonPath('conversation.service_request_id', $request->getKey());
    $conversation = Conversation::firstOrFail();

    $this->actingAs($customer, 'sanctum')->postJson("/api/customer/conversations/{$conversation->getKey()}/messages", ['body' => 'Please confirm your arrival time.'])
        ->assertCreated()->assertJsonPath('message.body', 'Please confirm your arrival time.');
    $this->actingAs($artisan, 'sanctum')->getJson("/api/artisan/conversations/{$conversation->getKey()}/messages")
        ->assertOk()->assertJsonCount(1, 'messages');

    $outsider = User::create(['name' => 'Conversation Outsider', 'email' => 'conversation-outsider@example.test', 'phone' => '677777777', 'password' => 'A-secure-password1', 'roles' => ['customer']]);
    $this->actingAs($outsider, 'sanctum')->getJson("/api/customer/conversations/{$conversation->getKey()}/messages")
        ->assertNotFound();
});

it('stores permitted attachments privately and rejects unsafe file types', function () {
    Storage::fake('local');
    [$customer, , $request] = conversationScenario();
    $this->actingAs($customer, 'sanctum')->getJson("/api/customer/service-requests/{$request->getKey()}/conversation")->assertOk();
    $conversation = Conversation::firstOrFail();

    $this->actingAs($customer, 'sanctum')->post("/api/customer/conversations/{$conversation->getKey()}/messages", [
        'attachments' => [UploadedFile::fake()->image('repair.jpg')],
    ])->assertCreated()->assertJsonPath('message.attachments.0.name', 'repair.jpg');

    $message = Message::firstOrFail();
    $attachment = $message->attachments[0];
    Storage::disk('local')->assertExists($attachment['path']);

    $this->actingAs($customer, 'sanctum')->post("/api/customer/conversations/{$conversation->getKey()}/messages", [
        'attachments' => [UploadedFile::fake()->create('unsafe.exe', 50, 'application/octet-stream')],
    ])->assertUnprocessable()->assertJsonValidationErrors('attachments.0');
});
