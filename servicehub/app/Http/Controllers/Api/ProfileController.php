<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Profile\StoreProfilePhotoRequest;
use App\Http\Requests\Profile\UpdateArtisanProfileRequest;
use App\Http\Requests\Profile\UpdateCustomerProfileRequest;
use App\Models\Artisan;
use App\Models\Customer;
use App\Services\ProfilePhotoService;
use Illuminate\Filesystem\FilesystemAdapter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    public function __construct(private readonly ProfilePhotoService $photos) {}

    public function customer(Request $request): JsonResponse
    {
        return response()->json(['profile' => $this->customerResponse($request->user(), $this->customerProfile($request))]);
    }

    public function updateCustomer(UpdateCustomerProfileRequest $request): JsonResponse
    {
        $data = $request->validated();
        $user = $request->user();
        $customer = $this->customerProfile($request);
        $updates = [];

        foreach (['default_location', 'preferences'] as $field) {
            if (array_key_exists($field, $data)) {
                if ($field === 'default_location') {
                    $updates['address_book'] = [$data[$field]];
                } else {
                    $updates[$field] = $data[$field];
                }
                unset($data[$field]);
            }
        }

        $user->update($data);
        $customer->update($updates);

        return response()->json(['profile' => $this->customerResponse($user->fresh(), $customer->fresh())]);
    }

    public function storePhoto(StoreProfilePhotoRequest $request): JsonResponse
    {
        $user = $this->photos->replace($request->user(), $request->file('photo'));

        return response()->json(['profile_photo' => $this->photos->metadata($user)], 201);
    }

    public function downloadPhoto(Request $request)
    {
        $photo = $this->photos->download($request->user());

        /** @var FilesystemAdapter $disk */
        $disk = Storage::disk('local');

        return $disk->download($photo['path'], 'profile-photo', ['Content-Type' => $photo['mime_type']]);
    }

    public function destroyPhoto(Request $request): JsonResponse
    {
        $this->photos->remove($request->user());

        return response()->json(status: 204);
    }

    public function artisan(Request $request): JsonResponse
    {
        return response()->json(['profile' => $this->artisanResponse($this->artisanProfile($request))]);
    }

    public function updateArtisan(UpdateArtisanProfileRequest $request): JsonResponse
    {
        $profile = $this->artisanProfile($request);
        $profile->update($request->validated());

        return response()->json(['profile' => $this->artisanResponse($profile->fresh())]);
    }

    private function customerProfile(Request $request): Customer
    {
        return $request->user()->customer()->firstOrCreate(['user_id' => $request->user()->getKey()]);
    }

    private function artisanProfile(Request $request): Artisan
    {
        return $request->user()->artisan()->firstOrFail();
    }

    private function artisanResponse(Artisan $profile): array
    {
        return [...$profile->toArray(), 'payout_phone_configured' => $profile->payout_phone !== null];
    }

    private function customerResponse($user, Customer $customer): array
    {
        $defaultLocation = $customer->address_book[0] ?? null;

        return [
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'profile_photo' => $this->photos->metadata($user),
            'customer' => $customer,
            // Temporary compatibility response; data is no longer persisted on User.
            'customer_profile' => ['default_location' => $defaultLocation, 'preferences' => $customer->preferences ?? []],
        ];
    }
}
