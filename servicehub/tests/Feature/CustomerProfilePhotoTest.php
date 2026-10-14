<?php

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

uses(DatabaseMigrations::class);

function photoCustomer(string $email = 'photo-customer@example.test'): User
{
    return User::create([
        'name' => 'Profile Photo Customer',
        'email' => $email,
        'phone' => '677'.random_int(100000, 999999),
        'password' => 'A-secure-password1',
        'roles' => ['customer'],
        'active_role' => 'customer',
    ]);
}

it('stores customer profile photos privately and returns only safe metadata', function () {
    Storage::fake('local');
    $customer = photoCustomer();

    $response = $this->actingAs($customer, 'sanctum')
        ->post('/api/customer/profile/photo', ['photo' => UploadedFile::fake()->image('portrait.jpg', 256, 256)]);

    $response->assertCreated()
        ->assertJsonPath('profile_photo.mime_type', 'image/jpeg')
        ->assertJsonMissingPath('profile_photo.path');

    $stored = $customer->fresh()->profile_photo;
    Storage::disk('local')->assertExists($stored['path']);

    $this->actingAs($customer, 'sanctum')->get('/api/customer/profile/photo')->assertOk();
});

it('replaces and removes a profile photo without accepting unsafe uploads', function () {
    Storage::fake('local');
    $customer = photoCustomer('photo-replacement@example.test');

    $this->actingAs($customer, 'sanctum')
        ->post('/api/customer/profile/photo', ['photo' => UploadedFile::fake()->image('first.png', 256, 256)])
        ->assertCreated();
    $firstPath = $customer->fresh()->profile_photo['path'];

    $this->actingAs($customer, 'sanctum')
        ->post('/api/customer/profile/photo', ['photo' => UploadedFile::fake()->image('second.webp', 256, 256)])
        ->assertCreated();
    Storage::disk('local')->assertMissing($firstPath);

    $this->actingAs($customer, 'sanctum')
        ->postJson('/api/customer/profile/photo', ['photo' => 'not-a-file'])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('photo');

    $this->actingAs($customer, 'sanctum')->deleteJson('/api/customer/profile/photo')->assertNoContent();
    expect($customer->fresh()->profile_photo)->toBeNull();
});

it('prevents non-customers from accessing customer profile photos', function () {
    $artisan = User::create([
        'name' => 'Photo Artisan', 'email' => 'photo-artisan@example.test', 'phone' => '677'.random_int(100000, 999999),
        'password' => 'A-secure-password1', 'roles' => ['artisan'], 'active_role' => 'artisan',
    ]);

    $this->actingAs($artisan, 'sanctum')->get('/api/customer/profile/photo')->assertForbidden();
});
