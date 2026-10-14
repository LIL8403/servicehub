<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\RejectArtisanRequest;
use App\Models\Artisan;
use App\Services\ArtisanVerificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class ArtisanVerificationController extends Controller
{
    public function __construct(
        private ArtisanVerificationService $verificationService
    ) {}

    public function pending(): JsonResponse
    {

        $artisans = $this->verificationService
            ->getPendingArtisans();

        return response()->json([
            'artisans' => $artisans,
        ]);
    }

    public function approve(Request $request, Artisan $artisan): JsonResponse
    {
        $artisan = $this->verificationService
            ->approve($artisan, $request->user());

        return response()->json([
            'message' => 'Artisan verified successfully.',
            'artisan_profile' => $artisan,
        ]);
    }

    public function reject(
        RejectArtisanRequest $request,
        Artisan $artisan
    ): JsonResponse {

        $artisan = $this->verificationService->reject(
            $artisan,
            $request->validated('rejection_reason'),
            $request->user(),
        );

        return response()->json([
            'message' => 'Artisan rejected successfully.',
            'artisan_profile' => $artisan,
        ]);
    }

    /**
     * Returns the artisan's current verification state. Used by the
     * verification hub to render status, sections, and next actions.
     */
    public function show(Request $request): JsonResponse
    {
        $artisan = $this->artisanFor($request);

        return response()->json([
            'verification' => $this->verificationPayload($artisan),
            'config' => [
                'identity_document_types' => config('verification.identity_document_types'),
                'supporting_document_types' => config('verification.supporting_document_types'),
                'max_supporting_documents' => config('verification.max_supporting_documents'),
                'max_file_size_kb' => config('verification.max_file_size_kb'),
            ],
        ]);
    }

    /**
     * Saves the identity text fields (legal name, DOB, address). Does
     * not accept file uploads — those use the upload endpoints.
     */
    public function saveIdentity(Request $request): JsonResponse
    {
        $artisan = $this->artisanFor($request);
        $this->ensureEditable($artisan);

        $data = $request->validate([
            'legal_name' => ['required', 'string', 'min:2', 'max:255'],
            'date_of_birth' => ['required', 'date', 'before:today'],
            'residential_address' => ['required', 'string', 'min:5', 'max:500'],
        ]);

        $artisan->update([
            'legal_name' => $data['legal_name'],
            'date_of_birth' => $data['date_of_birth'],
            'residential_address' => $data['residential_address'],
        ]);

        return response()->json(['verification' => $this->verificationPayload($artisan->fresh())]);
    }

    /**
     * Uploads the identity document (front image, optional back, and
     * document metadata).
     */
    public function uploadIdentityDocument(Request $request): JsonResponse
    {
        $artisan = $this->artisanFor($request);
        $this->ensureEditable($artisan);

        $request->validate([
            'document_type' => ['required', 'string', 'in:' . implode(',', $this->identityDocumentKeys())],
            'document_number' => ['required', 'string', 'min:3', 'max:100'],
            'expires_at' => ['nullable', 'date', 'after:today'],
            'front' => ['required', 'file', 'mimetypes:image/jpeg,image/png,image/webp', 'max:' . config('verification.max_file_size_kb', 5120)],
            'back' => ['nullable', 'file', 'mimetypes:image/jpeg,image/png,image/webp', 'max:' . config('verification.max_file_size_kb', 5120)],
        ]);

        $type = $request->input('document_type');
        $typeConfig = collect(config('verification.identity_document_types'))->firstWhere('key', $type);
        abort_unless($typeConfig, 422, 'Unknown identity document type.');

        if (($typeConfig['requires_back'] ?? false) && ! $request->hasFile('back')) {
            throw ValidationException::withMessages([
                'back' => ['This document type requires a back image.'],
            ]);
        }

        $front = $this->storeUpload($request->file('front'), $artisan, 'identity-front');
        $back = $request->hasFile('back')
            ? $this->storeUpload($request->file('back'), $artisan, 'identity-back')
            : null;

        $previous = $artisan->identity_document;

        $artisan->update([
            'identity_document' => [
                'type' => $type,
                'number' => $request->input('document_number'),
                'expires_at' => $request->input('expires_at'),
                'front' => $front,
                'back' => $back,
            ],
        ]);

        // Clean up the previously stored files if they were replaced.
        if (is_array($previous)) {
            foreach (['front', 'back'] as $slot) {
                $old = $previous[$slot]['path'] ?? null;
                if (is_string($old) && $old !== ($front['path'] ?? null)) {
                    Storage::disk('local')->delete($old);
                }
            }
        }

        return response()->json(['verification' => $this->verificationPayload($artisan->fresh())]);
    }

    /**
     * Stores the verification selfie captured on-device.
     */
    public function uploadSelfie(Request $request): JsonResponse
    {
        $artisan = $this->artisanFor($request);
        $this->ensureEditable($artisan);

        $request->validate([
            'selfie' => ['required', 'file', 'mimetypes:image/jpeg,image/png,image/webp', 'max:' . config('verification.max_file_size_kb', 5120)],
        ]);

        $previous = $artisan->verification_selfie;
        $selfie = $this->storeUpload($request->file('selfie'), $artisan, 'selfie');

        $artisan->update(['verification_selfie' => $selfie]);

        if (is_array($previous) && ! empty($previous['path']) && $previous['path'] !== $selfie['path']) {
            Storage::disk('local')->delete($previous['path']);
        }

        return response()->json(['verification' => $this->verificationPayload($artisan->fresh())]);
    }

    /**
     * Uploads a supporting document. These are optional.
     */
    public function uploadSupportingDocument(Request $request): JsonResponse
    {
        $artisan = $this->artisanFor($request);
        $this->ensureEditable($artisan);

        $existing = $artisan->verification_documents ?? [];
        $max = (int) config('verification.max_supporting_documents', 8);

        if (count($existing) >= $max) {
            throw ValidationException::withMessages([
                'document' => ['You have reached the maximum number of supporting documents.'],
            ]);
        }

        $request->validate([
            'document_type' => ['required', 'string', 'in:' . implode(',', $this->supportingDocumentKeys())],
            'label' => ['nullable', 'string', 'max:255'],
            'document' => ['required', 'file', 'mimetypes:image/jpeg,image/png,image/webp,application/pdf', 'max:' . config('verification.max_file_size_kb', 5120)],
        ]);

        $stored = $this->storeUpload($request->file('document'), $artisan, 'supporting');

        $entry = [
            'id' => (string) Str::uuid(),
            'type' => $request->input('document_type'),
            'label' => $request->input('label') ?: $this->supportingTypeLabel($request->input('document_type')),
            'file' => $stored,
            'uploaded_at' => now()->toIso8601String(),
        ];

        $artisan->update([
            'verification_documents' => [...$existing, $entry],
        ]);

        return response()->json(['verification' => $this->verificationPayload($artisan->fresh())]);
    }

    /**
     * Removes a supporting document by its id.
     */
    public function deleteSupportingDocument(Request $request, string $documentId): JsonResponse
    {
        $artisan = $this->artisanFor($request);
        $this->ensureEditable($artisan);

        $existing = $artisan->verification_documents ?? [];
        $entry = collect($existing)->firstWhere('id', $documentId);

        if ($entry === null) {
            abort(404, 'Supporting document not found.');
        }

        $path = $entry['file']['path'] ?? null;
        if (is_string($path) && $path !== '') {
            Storage::disk('local')->delete($path);
        }

        $remaining = collect($existing)->reject(fn($d) => $d['id'] === $documentId)->values()->all();

        $artisan->update(['verification_documents' => $remaining]);

        return response()->json(['verification' => $this->verificationPayload($artisan->fresh())]);
    }

    /**
     * Submits the verification application for review. All required
     * sections must be complete before this succeeds.
     */
    public function submit(Request $request): JsonResponse
    {
        $artisan = $this->artisanFor($request);
        $this->ensureEditable($artisan);

        $missing = $this->missingRequirements($artisan);
        if ($missing !== []) {
            throw ValidationException::withMessages(['verification' => $missing]);
        }

        $history = $artisan->verification_history ?? [];
        $history[] = [
            'event' => 'submitted',
            'occurred_at' => now()->toIso8601String(),
        ];

        $artisan->update([
            'verification_status' => 'pending',
            'verification_submitted_at' => now(),
            'verification_rejection_reason' => null,
            'verification_history' => $history,
        ]);

        return response()->json(['verification' => $this->verificationPayload($artisan->fresh())]);
    }

    /**
     * Streams a previously uploaded file back to the artisan for
     * preview. Only the owning artisan can download.
     */
    public function download(Request $request, string $slot)
    {
        $artisan = $this->artisanFor($request);

        $path = match ($slot) {
            'identity-front' => $artisan->identity_document['front']['path'] ?? null,
            'identity-back' => $artisan->identity_document['back']['path'] ?? null,
            'selfie' => $artisan->verification_selfie['path'] ?? null,
            default => null,
        };

        if (! is_string($path) || $path === '' || ! Storage::disk('local')->exists($path)) {
            abort(404);
        }

        return response()->streamDownload(function () use ($path): void {
            $stream = Storage::disk('local')->readStream($path);

            if ($stream !== false) {
                fpassthru($stream);
                fclose($stream);
            }
        }, basename($path));
    }

    /**
     * Streams a supporting document back to the artisan by its id.
     * Unlike the slot-based download, this targets entries inside the
     * verification_documents[] array.
     */
    public function downloadSupportingDocument(Request $request, string $documentId)
    {
        $artisan = $this->artisanFor($request);

        $documents = $artisan->verification_documents ?? [];
        $entry = collect($documents)->firstWhere('id', $documentId);

        if (! is_array($entry)) {
            abort(404, 'Supporting document not found.');
        }

        $path = $entry['file']['path'] ?? null;

        if (! is_string($path) || $path === '' || ! Storage::disk('local')->exists($path)) {
            abort(404);
        }

        $filename = $entry['file']['name']
            ?? basename($path);

        return response()->streamDownload(function () use ($path): void {
            $stream = Storage::disk('local')->readStream($path);

            if ($stream !== false) {
                fpassthru($stream);
                fclose($stream);
            }
        }, $filename);
    }

    // ============================================================
    // Helpers
    // ============================================================

    private function artisanFor(Request $request): Artisan
    {
        $user = $request->user();
        $artisan = $user->artisan()->first();

        if (! $artisan) {
            $artisan = Artisan::create([
                'user_id' => $user->_id,
                'verification_status' => 'unverified',
            ]);
        }

        return $artisan;
    }

    private function ensureEditable(Artisan $artisan): void
    {
        $status = $artisan->verification_status?->value ?? (string) $artisan->verification_status;

        if (! in_array($status, ['unverified', 'rejected'], true)) {
            throw ValidationException::withMessages([
                'verification' => ['Your verification cannot be edited while it is ' . $status . '.'],
            ]);
        }
    }

    private function storeUpload($file, Artisan $artisan, string $slot): array
    {
        $id = (string) Str::uuid();
        $directory = 'verification/' . $artisan->getKey();
        $extension = $file->getClientOriginalExtension() ?: $file->extension() ?: 'bin';
        $path = $file->storeAs($directory, $slot . '-' . $id . '.' . $extension, 'local');

        return [
            'id' => $id,
            'path' => $path,
            'name' => $file->getClientOriginalName(),
            'mime_type' => $file->getClientMimeType() ?? 'application/octet-stream',
            'size' => $file->getSize() ?? 0,
        ];
    }

    private function identityDocumentKeys(): array
    {
        return collect(config('verification.identity_document_types'))
            ->pluck('key')
            ->all();
    }

    private function supportingDocumentKeys(): array
    {
        return collect(config('verification.supporting_document_types'))
            ->pluck('key')
            ->all();
    }

    private function supportingTypeLabel(string $key): string
    {
        return (string) collect(config('verification.supporting_document_types'))
            ->firstWhere('key', $key)['label'] ?? $key;
    }

    private function missingRequirements(Artisan $artisan): array
    {
        $missing = [];

        if (empty($artisan->legal_name)) {
            $missing[] = 'Legal name is required.';
        }
        if (empty($artisan->date_of_birth)) {
            $missing[] = 'Date of birth is required.';
        }
        if (empty($artisan->residential_address)) {
            $missing[] = 'Residential address is required.';
        }

        $identity = $artisan->identity_document;
        if (! is_array($identity) || empty($identity['type']) || empty($identity['front'])) {
            $missing[] = 'Identity document is required.';
        }

        if (! is_array($artisan->verification_selfie) || empty($artisan->verification_selfie['path'])) {
            $missing[] = 'Verification selfie is required.';
        }

        // Professional fields are stored on the Artisan profile already.
        if (empty($artisan->professional_title) || empty($artisan->service_offerings)) {
            $missing[] = 'Complete your professional profile before submitting.';
        }

        return $missing;
    }

    private function verificationPayload(Artisan $artisan): array
    {
        $status = $artisan->verification_status?->value ?? (string) $artisan->verification_status;

        return [
            'status' => $status,
            'legal_name' => $artisan->legal_name,
            'date_of_birth' => $artisan->date_of_birth
                ? \Illuminate\Support\Carbon::parse($artisan->date_of_birth)->toDateString()
                : null,
            'residential_address' => $artisan->residential_address,
            'identity_document' => $artisan->identity_document,
            'selfie' => $artisan->verification_selfie,
            'supporting_documents' => $artisan->verification_documents ?? [],
            'submitted_at' => $artisan->verification_submitted_at?->toIso8601String(),
            'rejection_reason' => $artisan->verification_rejection_reason,
            'history' => $artisan->verification_history ?? [],
            'sections' => [
                'identity' => $this->identitySectionState($artisan),
                'professional' => $this->professionalSectionState($artisan),
                'supporting' => $this->supportingSectionState($artisan),
            ],
        ];
    }

    private function identitySectionState(Artisan $artisan): array
    {
        $complete = ! empty($artisan->legal_name)
            && ! empty($artisan->date_of_birth)
            && ! empty($artisan->residential_address)
            && is_array($artisan->identity_document)
            && ! empty($artisan->identity_document['front'])
            && is_array($artisan->verification_selfie)
            && ! empty($artisan->verification_selfie['path']);

        return ['complete' => $complete];
    }

    private function professionalSectionState(Artisan $artisan): array
    {
        $complete = ! empty($artisan->professional_title)
            && ! empty($artisan->service_offerings);

        return ['complete' => $complete];
    }

    private function supportingSectionState(Artisan $artisan): array
    {
        $count = count($artisan->verification_documents ?? []);

        // The section is complete only when the artisan has actually
        // added at least one document. It is allowed to submit without
        // any documents (supporting docs are optional), but the UI
        // should not claim the section is complete in that case.
        return [
            'complete' => $count > 0,
            'count' => $count,
        ];
    }

    /**
     * Streams a verification document for admin review.
     *
     * Slots:
     *   identity-front   → the front image of the ID document
     *   identity-back    → the back image (CNI only)
     *   selfie           → the verification selfie
     *   document:{id}    → a supporting document by its uuid
     */
    public function downloadDocument(Request $request, Artisan $artisan, string $slot)
    {
        $path = null;

        if ($slot === 'identity-front') {
            $path = $artisan->identity_document['front']['path'] ?? null;
        } elseif ($slot === 'identity-back') {
            $path = $artisan->identity_document['back']['path'] ?? null;
        } elseif ($slot === 'selfie') {
            $path = $artisan->verification_selfie['path'] ?? null;
        } elseif (str_starts_with($slot, 'document:')) {
            $id = substr($slot, strlen('document:'));
            $documents = $artisan->verification_documents ?? [];
            $entry = collect($documents)->firstWhere('id', $id);
            $path = $entry['file']['path'] ?? null;
        }

        if (! is_string($path) || $path === '' || ! Storage::disk('local')->exists($path)) {
            abort(404);
        }

        return response()->streamDownload(function () use ($path): void {
            $stream = Storage::disk('local')->readStream($path);

            if ($stream !== false) {
                fpassthru($stream);
                fclose($stream);
            }
        }, basename($path));
    }
}
