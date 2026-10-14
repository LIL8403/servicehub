<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Conversation\StoreMessageRequest;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\ServiceRequest;
use App\Services\ConversationService;
use Illuminate\Filesystem\FilesystemAdapter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ConversationController extends Controller
{
    public function __construct(private readonly ConversationService $conversations) {}

    public function show(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        return response()->json(['conversation' => $this->conversationPayload($this->conversations->forServiceRequest($serviceRequest, $request->user()))]);
    }

    public function messages(Request $request, Conversation $conversation): JsonResponse
    {
        return response()->json(['messages' => $this->conversations->messages($conversation, $request->user())->map($this->messagePayload(...))]);
    }

    public function store(StoreMessageRequest $request, Conversation $conversation): JsonResponse
    {
        $message = $this->conversations->send($conversation, $request->user(), $request->validated());

        return response()->json(['message' => $this->messagePayload($message)], 201);
    }

    public function download(Request $request, Conversation $conversation, Message $message, string $attachmentId)
    {
        $attachment = $this->conversations->attachment($conversation, $message, $request->user(), $attachmentId);

        /** @var FilesystemAdapter $disk */
        $disk = Storage::disk('local');

        return $disk->download($attachment['path'], $attachment['name'], ['Content-Type' => $attachment['mime_type']]);
    }

    private function conversationPayload(Conversation $conversation): array
    {
        return ['id' => $conversation->getKey(), 'service_request_id' => $conversation->service_request_id, 'created_at' => $conversation->created_at, 'updated_at' => $conversation->updated_at];
    }

    private function messagePayload(Message $message): array
    {
        return [
            'id' => $message->getKey(),
            'conversation_id' => $message->conversation_id,
            'sender_id' => $message->sender_id,
            'body' => $message->body,
            'created_at' => $message->created_at,
            'read_at' => $message->read_at,
            'attachments' => collect($message->attachments ?? [])->map(
                fn(array $attachment) => [
                    'id' => $attachment['id'],
                    'name' => $attachment['name'],
                    'mime_type' => $attachment['mime_type'],
                    'size' => $attachment['size'],
                ]
            )->values(),
        ];
    }
}
