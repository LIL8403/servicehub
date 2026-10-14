<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Artisan;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;

class ArtisanConversationController extends Controller
{
    /**
     * Lists every conversation belonging to the authenticated artisan,
     * enriched with the last message, the unread count, and the
     * customer's identity.
     *
     * Sorted newest-first by the timestamp of the last message.
     *
     * Mirrors CustomerConversationController but swaps the "other
     * party" from artisan to customer.
     */
    public function index(Request $request): JsonResponse
    {
        $artisan = $request->user()->artisan()->first();
        abort_unless($artisan, 404, 'Artisan profile not found.');

        $artisanId = (string) $artisan->getKey();

        $conversations = Conversation::query()
            ->where('artisan_profile_id', $artisanId)
            ->get();

        if ($conversations->isEmpty()) {
            return response()->json(['conversations' => []]);
        }

        $messagesByConversation = $this->loadConversationMessages($conversations);
        $requests = $this->loadServiceRequests($conversations);
        $customers = $this->loadCustomers($requests);

        $payload = $this->buildConversationPayload(
            $conversations,
            $messagesByConversation,
            $requests,
            $customers,
            $artisanId,
        );

        return response()->json(['conversations' => $payload]);
    }

    private function loadConversationMessages(Collection $conversations): Collection
    {
        $conversationIds = $conversations
            ->map(fn(Conversation $c) => (string) $c->getKey())
            ->all();

        return Message::query()
            ->whereIn('conversation_id', $conversationIds)
            ->orderBy('created_at', 'asc')
            ->get()
            ->groupBy('conversation_id');
    }

    private function loadServiceRequests(Collection $conversations): Collection
    {
        $requestIds = $conversations
            ->pluck('service_request_id')
            ->filter()
            ->map(fn($id) => (string) $id)
            ->unique()
            ->values()
            ->all();

        if ($requestIds === []) {
            return collect();
        }

        return ServiceRequest::query()
            ->whereIn('_id', $requestIds)
            ->with(['service', 'customer'])
            ->get()
            ->keyBy(fn(ServiceRequest $sr) => (string) $sr->getKey());
    }

    /**
     * Customers aren't a separate collection the way artisans are —
     * a "customer" here is a User with a customer_id on the request.
     * We resolve the users in one query.
     */
    private function loadCustomers(Collection $requests): Collection
    {
        $customerIds = $requests
            ->pluck('customer_id')
            ->filter()
            ->map(fn($id) => (string) $id)
            ->unique()
            ->values()
            ->all();

        if ($customerIds === []) {
            return collect();
        }

        return User::query()
            ->whereIn('_id', $customerIds)
            ->get()
            ->keyBy(fn(User $u) => (string) $u->getKey());
    }

    private function buildConversationPayload(
        Collection $conversations,
        Collection $messagesByConversation,
        Collection $requests,
        Collection $customers,
        string $artisanId,
    ): Collection {
        return $conversations
            ->filter(function (Conversation $conversation) use ($requests) {
                // Drop orphaned conversations — the ServiceRequest
                // they point to has been deleted. Without this, the
                // list shows dead entries that 404 when tapped.
                return $requests->has((string) $conversation->service_request_id);
            })
            ->map(function (Conversation $conversation) use (
                $messagesByConversation,
                $requests,
                $customers,
                $artisanId,
            ) {
                $id = (string) $conversation->getKey();
                $messages = $messagesByConversation->get($id) ?? collect();
                $lastMessage = $messages->last();

                // Unread = messages from the OTHER party that we
                // haven't read yet. The artisan's own messages never
                // count as unread.
                $unreadCount = $messages
                    ->filter(fn(Message $m) =>
                    (string) $m->sender_id !== $artisanId
                        && empty($m->read_at))
                    ->count();

                $request = $requests->get((string) $conversation->service_request_id);
                $customer = $request
                    ? $customers->get((string) $request->customer_id)
                    : null;

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
                    'customer' => $customer ? [
                        'id' => (string) $customer->getKey(),
                        'name' => $customer->name ?? '',
                        'first_name' => $customer->first_name ?? '',
                        'last_name' => $customer->last_name ?? '',
                        'has_photo' => ! empty($customer->profile_photo),
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

                return is_string($timestamp)
                    ? $timestamp
                    : $timestamp->toDateTimeString();
            })
            ->values();
    }
}
