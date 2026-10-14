<?php

namespace App\Services;

use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use RuntimeException;

class ServiceRequestMediaService
{
    /** @param array<int, UploadedFile> $images */
    public function attachImages(ServiceRequest $serviceRequest, array $images): ServiceRequest
    {
        if ($images === []) {
            return $serviceRequest;
        }

        $attachments = [];

        try {
            foreach ($images as $image) {
                $path = $image->store("service-requests/{$serviceRequest->getKey()}", 'local');

                if (! is_string($path) || $path === '') {
                    throw new RuntimeException('The image could not be stored.');
                }

                $attachments[] = [
                    'id' => (string) Str::uuid(),
                    'path' => $path,
                    'name' => $this->safeName($image),
                    'mime_type' => $image->getMimeType(),
                    'size' => $image->getSize(),
                ];
            }
        } catch (\Throwable $exception) {
            Storage::disk('local')->delete(collect($attachments)->pluck('path')->all());

            throw $exception;
        }

        try {
            $serviceRequest->update([
                'images' => [...($serviceRequest->images ?? []), ...$attachments],
            ]);
        } catch (\Throwable $exception) {
            Storage::disk('local')->delete(collect($attachments)->pluck('path')->all());

            throw $exception;
        }

        return $serviceRequest->fresh();
    }

    public function imageForCustomer(ServiceRequest $serviceRequest, User $customer, string $imageId): array
    {
        abort_unless($serviceRequest->customer_id === $customer->getKey(), 404);

        return $this->image($serviceRequest, $imageId);
    }

    public function imageForSelectedArtisan(ServiceRequest $serviceRequest, User $artisan, string $imageId): array
    {
        $profile = $artisan->artisan()->first();
        abort_unless($profile !== null && $serviceRequest->selected_artisan_id === $profile->getKey(), 404);

        return $this->image($serviceRequest, $imageId);
    }

    private function image(ServiceRequest $serviceRequest, string $imageId): array
    {
        $image = collect($serviceRequest->images ?? [])->firstWhere('id', $imageId);
        abort_unless($image !== null && Storage::disk('local')->exists($image['path']), 404);

        return $image;
    }

    private function safeName(UploadedFile $image): string
    {
        $name = basename($image->getClientOriginalName());
        $name = preg_replace('/[^\pL\pN._ -]/u', '_', $name) ?: 'image';

        return Str::limit($name, 255, '');
    }
}
