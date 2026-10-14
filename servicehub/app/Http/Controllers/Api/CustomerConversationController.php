<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Artisan;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\ServiceRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CustomerConversationController extends Controller
{
    /**
     * Lists every conversation belonging to the authenticated customer,
     * enriched with the last message, the unread count, and the
     * artisan's identity.
     *
     * Sorted newest-first by the timestamp of the last message.
     */
    public function index(Request $request): JsonResponse
    {
        $customerId = (string) $request->user()->getKey();

        $conversations = Conversation::query()
            ->where('customer_id', $customerId)
            ->get();

        if ($conversations->isEmpty()) {
            return response()->json(['conversations' => []]);
        }

        $messagesByConversation = $this->loadConversationMessages($conversations);
        $requests = $this->loadServiceRequests($conversations);
        $artisans = $this->loadArtisans($conversations);

        $payload = $this->buildConversationPayload(
            $conversations,
            $messagesByConversation,
            $requests,
            $artisans,
            $customerId,
        );

        return response()->json(['conversations' => $payload]);
    }

    private function loadConversationMessages(\Illuminate\Support\Collection $conversations): \Illuminate\Support\Collection
    {
        $conversationIds = $conversations
            ->map(fn(Conversation $conversation) => (string) $conversation->getKey())
            ->all();

        return Message::query()
            ->whereIn('conversation_id', $conversationIds)
            ->orderBy('created_at', 'asc')
            ->get()
            ->groupBy('conversation_id');
    }

    private function loadServiceRequests(\Illuminate\Support\Collection $conversations): \Illuminate\Support\Collection
    {
        $serviceRequestIds = $conversations
            ->pluck('service_request_id')
            ->filter()
            ->map(fn($id) => (string) $id)
            ->unique()
            ->values()
            ->all();

        if ($serviceRequestIds === []) {
            return collect();
        }

        return ServiceRequest::query()
            ->whereIn('_id', $serviceRequestIds)
            ->with(['service', 'selectedArtisan.user'])
            ->get()
            ->keyBy(fn(ServiceRequest $serviceRequest) => (string) $serviceRequest->getKey());
    }

    private function loadArtisans(\Illuminate\Support\Collection $conversations): \Illuminate\Support\Collection
    {
        $artisanProfileIds = $conversations
            ->pluck('artisan_profile_id')
            ->filter()
            ->map(fn($id) => (string) $id)
            ->unique()
            ->values()
            ->all();

        if ($artisanProfileIds === []) {
            return collect();
        }

        return Artisan::query()
            ->whereIn('_id', $artisanProfileIds)
            ->with('user')
            ->get()
            ->keyBy(fn(Artisan $artisan) => (string) $artisan->getKey());
    }

    private function buildConversationPayload(
        \Illuminate\Support\Collection $conversations,
        \Illuminate\Support\Collection $messagesByConversation,
        \Illuminate\Support\Collection $requests,
        \Illuminate\Support\Collection $artisans,
        string $customerId,
    ): \Illuminate\Support\Collection {
        return $conversations
            ->filter(function (Conversation $conversation) use ($requests) {
                // Drop orphaned conversations — the ServiceRequest
                // they point to has been deleted. Without this, the
                // list shows dead entries that 404 when tapped.
                return $requests->has((string) $conversation->service_request_id);
            })
            ->map(function (Conversation $conversation) use ($messagesByConversation, $requests, $artisans, $customerId) {
                $id = (string) $conversation->getKey();
                $messages = $messagesByConversation->get($id) ?? collect();
                $lastMessage = $messages->last();

                $unreadCount = $messages
                    ->filter(fn(Message $message) => (string) $message->sender_id !== $customerId
                        && empty($message->read_at))
                    ->count();

                $artisan = $artisans->get((string) $conversation->artisan_profile_id);
                $user = $artisan?->user;
                $request = $requests->get((string) $conversation->service_request_id);

                return [
                    'id' => $id,
                    'service_request_id' => (string) $conversation->service_request_id,
                    'updated_at' => $conversation->updated_at,
                    'last_message' => $lastMessage ? [
                        'id' => (string) $lastMessage->getKey(),
                        'sender_id' => (string) $lastMessage->sender_id,
                        'body' => (string) ($lastMessage->body ?? ''),
                        'attachments_count' => count($lastMessage->attachments ?? []),
                        'created_at' => $lastMessage->created_at,
                        'read_at' => $lastMessage->read_at,
                    ] : null,
                    'unread_count' => $unreadCount,
                    'artisan' => $user ? [
                        'id' => (string) $user->getKey(),
                        'name' => $user->name ?? '',
                        'first_name' => $user->first_name ?? '',
                        'last_name' => $user->last_name ?? '',
                        'has_photo' => ! empty($user->profile_photo),
                    ] : null,
                    'service' => $request?->service ? [
                        'id' => (string) $request->service->getKey(),
                        'name' => $request->service->name,
                    ] : null,
                ];
            })
            ->sortByDesc(function (array $entry) {
                $timestamp = $entry['last_message']['created_at']
                    ?? $entry['updated_at']
                    ?? now();

                return is_string($timestamp) ? $timestamp : $timestamp->toDateTimeString();
            })
            ->values();
    }
}
