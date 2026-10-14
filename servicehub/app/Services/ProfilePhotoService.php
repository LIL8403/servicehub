<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use RuntimeException;

class ProfilePhotoService
{
    public function replace(User $user, UploadedFile $photo): User
    {
        $path = $photo->store("profile-photos/{$user->getKey()}", 'local');
        if (! is_string($path) || $path === '') {
            throw new RuntimeException('The profile photo could not be stored.');
        }

        $previous = $user->profile_photo;
        $metadata = [
            'path' => $path,
            'mime_type' => $photo->getMimeType(),
            'size' => $photo->getSize(),
            'updated_at' => now(),
        ];

        try {
            $user->forceFill(['profile_photo' => $metadata])->save();
        } catch (\Throwable $exception) {
            Storage::disk('local')->delete($path);

            throw $exception;
        }

        if (is_array($previous) && isset($previous['path']) && $previous['path'] !== $path) {
            Storage::disk('local')->delete($previous['path']);
        }

        return $user->fresh();
    }

    public function remove(User $user): User
    {
        $previous = $user->profile_photo;
        $user->forceFill(['profile_photo' => null])->save();

        if (is_array($previous) && isset($previous['path'])) {
            Storage::disk('local')->delete($previous['path']);
        }

        return $user->fresh();
    }

    /** @return array{path: string, mime_type: string} */
    public function download(User $user): array
    {
        $photo = $user->profile_photo;
        abort_unless(is_array($photo) && isset($photo['path'], $photo['mime_type']) && Storage::disk('local')->exists($photo['path']), 404);

        return $photo;
    }

    public function metadata(User $user): ?array
    {
        $photo = $user->profile_photo;
        if (! is_array($photo)) {
            return null;
        }

        return [
            'mime_type' => $photo['mime_type'] ?? null,
            'size' => $photo['size'] ?? null,
            'updated_at' => $photo['updated_at'] ?? null,
        ];
    }
}
