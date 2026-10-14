<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * Handles file uploads for dispute evidence.
 *
 * The customer or artisan uploads one or more files here, receives
 * reference strings back, and then passes those strings in the
 * `evidence[]` array when opening a dispute or adding to an existing
 * one. This two-phase flow lets a single upload be reused across
 * updates on the same dispute.
 */
class DisputeEvidenceController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'files' => ['required', 'array', 'max:5'],
            'files.*' => [
                'file',
                'mimetypes:image/jpeg,image/png,image/webp,application/pdf',
                'max:5120',
            ],
        ]);

        $references = [];

        foreach ($validated['files'] as $file) {
            $path = $file->store('disputes/evidence', 'local');
            $id = (string) Str::uuid();

            $references[] = [
                'id' => $id,
                'path' => $path,
                'name' => $file->getClientOriginalName(),
                'mime_type' => $file->getClientMimeType() ?? 'application/octet-stream',
                'size' => $file->getSize() ?? 0,
            ];
        }

        return response()->json(['references' => $references], 201);
    }
}