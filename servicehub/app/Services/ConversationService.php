<?php

namespace App\Services;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class ConversationService
{
    public function forServiceRequest(ServiceRequest $request, User $user): Conversation
    {
        $this->ensureParticipant($request, $user);
        if (! $request->selected_artisan_id) {
            throw ValidationException::withMessages(['service_request' => ['A conversation is available after an artisan has been selected.']]);
        }

        return Conversation::query()->firstOrCreate(
            ['service_request_id' => $request->getKey()],
            ['customer_id' => $request->customer_id, 'artisan_profile_id' => $request->selected_artisan_id],
        );
    }

    public function messages(Conversation $conversation, User $user): mixed
    {
        $this->ensureConversationParticipant($conversation, $user);

        return Message::query()->where('conversation_id', $conversation->getKey())->orderBy('created_at')->get();
    }

    public function send(Conversation $conversation, User $sender, array $data): Message
    {
        $this->ensureConversationParticipant($conversation, $sender);
        $attachments = collect($data['attachments'] ?? [])->map(fn (UploadedFile $file) => $this->storeAttachment($conversation, $file))->all();

        $message = Message::create([
            'conversation_id' => $conversation->getKey(),
            'sender_id' => $sender->getKey(),
            'body' => $data['body'] ?? null,
            'attachments' => $attachments,
        ]);
        $conversation->touch();

        return $message;
    }

    public function attachment(Conversation $conversation, Message $message, User $user, string $attachmentId): array
    {
        $this->ensureConversationParticipant($conversation, $user);
        abort_unless($message->conversation_id === $conversation->getKey(), 404);

        $attachment = collect($message->attachments ?? [])->firstWhere('id', $attachmentId);
        abort_unless($attachment && Storage::disk('local')->exists($attachment['path']), 404);

        return $attachment;
    }

    private function ensureConversationParticipant(Conversation $conversation, User $user): void
    {
        $request = ServiceRequest::query()->findOrFail($conversation->service_request_id);
        $this->ensureParticipant($request, $user);
    }

    private function ensureParticipant(ServiceRequest $request, User $user): void
    {
        if ($request->customer_id === $user->getKey()) {
            return;
        }

        $profile = $user->artisan()->first();
        abort_unless($profile && $request->selected_artisan_id === $profile->getKey(), 404);
    }

    private function storeAttachment(Conversation $conversation, UploadedFile $file): array
    {
        $path = $file->store("conversations/{$conversation->getKey()}", 'local');

        return [
            'id' => (string) Str::uuid(),
            'path' => $path,
            'name' => Str::limit($file->getClientOriginalName(), 255, ''),
            'mime_type' => $file->getMimeType(),
            'size' => $file->getSize(),
        ];
    }
}
