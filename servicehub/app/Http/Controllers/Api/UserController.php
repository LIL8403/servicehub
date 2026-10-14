<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class UserController extends Controller
{
    public function photo(Request $request, User $user)
    {
        abort_unless($request->user() !== null, 401);

        $photo = $user->profile_photo;
        $path = is_array($photo) ? ($photo['path'] ?? null) : $photo;

        if (! $path || ! Storage::disk('local')->exists($path)) {
            abort(404);
        }

        $mimeType = is_array($photo)
            ? ($photo['mime_type'] ?? 'image/jpeg')
            : 'image/jpeg';

        $filename = basename($path);

        return response()->streamDownload(
            function () use ($path) {
                echo Storage::disk('local')->get($path);
            },
            $filename,
            ['Content-Type' => $mimeType],
        );
    }
}
