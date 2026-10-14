<?php

namespace App\Services\Ai;

use App\Ai\Agents\AnomalyDetector;
use App\Ai\Agents\ArtisanRecommender;
use App\Ai\Agents\QuotationAnalyzer;
use App\Ai\Agents\RequestUnderstandingAgent;
use App\Enums\VerificationStatus;
use App\Models\Artisan;
use App\Models\Payment;
use App\Models\ServiceRequest;
use Illuminate\Support\Facades\Log;
use Laravel\Ai\Responses\StructuredAgentResponse;
use UnexpectedValueException;
use App\Models\Service;

class AiOrchestrationService
{
    public function understandRequest(ServiceRequest $request): array
    {
        if (! $this->isConfigured()) {
            return ['available' => false, 'reason' => 'unavailable'];
        }

        try {
            $response = RequestUnderstandingAgent::make()->prompt(json_encode([
                'description' => $request->description,
                'service_id' => $request->service_id,
                'preferred_schedule' => $request->preferred_schedule,
            ], JSON_THROW_ON_ERROR));
            $result = $this->structuredResult($response);

            if (($result['confidence_score'] ?? 0) < 40) {
                return ['available' => false, 'reason' => 'low_confidence'];
            }

            return ['available' => true, 'provider' => 'Gemini', 'model' => 'gemini-3.5-flash-lite', 'analyzed_at' => now(), 'result' => $result];
        } catch (\Throwable $exception) {
            Log::warning('AI request understanding unavailable.', ['request_id' => $request->getKey(), 'exception' => $exception::class]);

            return ['available' => false, 'reason' => 'unavailable'];
        }
    }

    public function recommendArtisans(ServiceRequest $request): array
    {
        $candidates = $this->candidates($request);
        $fallback = $this->fallback($candidates);

        if (! $this->isConfigured()) {
            return ['source' => 'deterministic_fallback', 'recommendations' => $fallback];
        }

        try {
            $response = ArtisanRecommender::make()->prompt(json_encode([
                'request' => ['description' => $request->description, 'service_id' => $request->service_id, 'location' => $request->location],
                'candidates' => $candidates,
            ], JSON_THROW_ON_ERROR));
            $result = $this->structuredResult($response);
            $recommendations = collect($result['recommendations'] ?? [])
                ->filter(fn($item) => is_array($item) && isset($item['artisan_id']) && array_key_exists($item['artisan_id'], $candidates) && ($item['confidence_score'] ?? 0) >= 40)
                ->values()->all();

            if ($recommendations === []) {
                return ['source' => 'deterministic_fallback', 'recommendations' => $fallback];
            }

            return ['source' => 'ai', 'provider' => 'Gemini', 'model' => 'gemini-3.5-flash-lite', 'generated_at' => now(), 'recommendations' => $recommendations];
        } catch (\Throwable $exception) {
            Log::warning('AI artisan recommendation unavailable.', ['request_id' => $request->getKey(), 'exception' => $exception::class]);

            return ['source' => 'deterministic_fallback', 'recommendations' => $fallback];
        }
    }

    /**
     * Understand a raw request description before it is persisted.
     * Used by the create-request wizard's optional "Improve with AI" action.
     *
     * Returns the same envelope shape as understandRequest() so the
     * frontend can reuse the same parser.
     */
    public function understandDraft(string $description, ?string $serviceId = null, mixed $preferredSchedule = null): array
    {
        if (! $this->isConfigured()) {
            return ['available' => false, 'reason' => 'unavailable'];
        }

        if (trim($description) === '') {
            return ['available' => false, 'reason' => 'empty_description'];
        }

        try {
            $response = RequestUnderstandingAgent::make()->prompt(json_encode([
                'description' => $description,
                'service_id' => $serviceId,
                'preferred_schedule' => $preferredSchedule,
            ], JSON_THROW_ON_ERROR));
            $result = $this->structuredResult($response);

            if (($result['confidence_score'] ?? 0) < 40) {
                return ['available' => false, 'reason' => 'low_confidence'];
            }

            return [
                'available' => true,
                'provider' => 'gemini',
                'model' => 'gemini-3.5-flash-lite',
                'analyzed_at' => now(),
                'result' => $result,
            ];
        } catch (\Throwable $exception) {
            Log::warning('AI draft understanding unavailable.', [
                'exception' => $exception::class,
            ]);

            return ['available' => false, 'reason' => 'unavailable'];
        }
    }

    /**
     * Persist a quotation analysis for the given request.
     *
     * Delegates the actual prompt and payload construction to
     * analyzeQuotationForCustomer() so both the artisan-submission
     * path and the customer-tap path use exactly the same inputs.
     * That keeps the stored analysis in sync with what the customer
     * sees when they tap "Analyze Quotation".
     */
    public function analyzeQuotation(ServiceRequest $request): void
    {
        $analysis = $this->analyzeQuotationForCustomer($request);

        if (($analysis['available'] ?? false) !== true) {
            return;
        }

        $this->persistAnalysis($request, $analysis);
    }

    /**
     * Store an analysis envelope into the request's quotation block.
     * Shared by analyzeQuotation() (submission path) and the customer
     * endpoint (tap path).
     *
     * @param  array{available:bool,provider?:string,model?:string,analyzed_at?:mixed,result?:array}  $analysis
     */
    public function persistAnalysis(ServiceRequest $request, array $analysis): void
    {
        $quotation = $request->quotation ?? [];
        $quotation['ai_analysis'] = [
            'available' => true,
            'provider' => $analysis['provider'] ?? 'gemini',
            'model' => $analysis['model'] ?? 'gemini-3.5-flash-lite',
            'analyzed_at' => $analysis['analyzed_at'] ?? now(),
            'result' => $analysis['result'] ?? [],
        ];
        $request->update(['quotation' => $quotation]);
    }

    /**
     * Return quotation analysis for a customer without persisting it.
     * Advisory only. Never accepts, rejects, or alters a quotation.
     *
     * Returns the same envelope shape used by the other AI methods so the
     * frontend can render a graceful fallback on failure.
     */
    public function analyzeQuotationForCustomer(ServiceRequest $request): array
    {
        if (! $this->isConfigured()) {
            return ['available' => false, 'reason' => 'unavailable'];
        }

        if (empty($request->quotation)) {
            return ['available' => false, 'reason' => 'no_quotation'];
        }

        try {
            $service = Service::query()
                ->where('_id', (string) $request->service_id)
                ->first();
            $serviceSlug = $service?->slug;
            $serviceName = $service?->name ?? 'this service';

            // Resolve the environment's reference range track. Demo
            // environments use small amounts because the payment
            // gateway caps transactions; production uses real market
            // ranges. Both share the same shape.
            $mode = $this->paymentMode();
            $range = $serviceSlug
                ? data_get(config('quotation_ranges'), "{$mode}.{$serviceSlug}")
                : null;

            $quotation = is_array($request->quotation)
                ? $request->quotation
                : (array) $request->quotation;

            $labour = (float) ($quotation['labor_amount']
                ?? $quotation['labour_amount']
                ?? 0);
            $materials = (float) ($quotation['materials_amount']
                ?? collect($request->materials ?? [])->sum('estimated_cost'));
            $total = (float) ($quotation['total'] ?? ($labour + $materials));

            $modeNote = $mode === 'demo'
                ? 'This environment operates with a payment gateway that '
                . 'caps transaction amounts at small values. Apply the '
                . 'reference range as given; do not treat the low '
                . 'absolute amounts as unusual.'
                : 'This environment operates with real payment amounts in '
                . 'XAF. Compare the quotation against the reference '
                . 'range as given.';

            $response = QuotationAnalyzer::make()->prompt(json_encode([
                'request_description' => $request->description,
                'service' => [
                    'id' => (string) $request->service_id,
                    'name' => $serviceName,
                    'slug' => $serviceSlug,
                ],
                'quotation' => [
                    'labour_amount' => $labour,
                    'materials_amount' => $materials,
                    'total' => $total,
                    'currency' => $quotation['currency'] ?? 'XAF',
                    'scope' => $quotation['scope'] ?? null,
                ],
                'reference_range' => $range,
                'mode_note' => $modeNote,
            ], JSON_THROW_ON_ERROR));

            $result = $this->structuredResult($response);

            return [
                'available' => true,
                'provider' => 'gemini',
                'model' => 'gemini-3.5-flash-lite',
                'analyzed_at' => now(),
                'result' => $result,
            ];
        } catch (\Throwable $exception) {
            Log::warning('AI quotation analysis unavailable.', [
                'request_id' => $request->getKey(),
                'exception' => $exception::class,
            ]);

            return ['available' => false, 'reason' => 'unavailable'];
        }
    }

    /**
     * Resolve the active payment mode. Demo environments use small
     * reference ranges because the gateway caps transactions.
     */
    private function paymentMode(): string
    {
        $mode = strtolower((string) config('services.campay.mode', 'production'));

        // Accept 'dev', 'development', 'demo' as demo mode.
        if (in_array($mode, ['dev', 'development', 'demo', 'test', 'sandbox'], true)) {
            return 'demo';
        }

        return 'production';
    }

    public function detectPaymentAnomaly(Payment $payment): void
    {
        if (! $this->isConfigured()) {
            return;
        }

        try {
            $response = AnomalyDetector::make()->prompt(json_encode([
                'amount' => $payment->amount,
                'currency' => $payment->currency,
                'status' => $payment->status->value,
                'payment_count_for_customer' => Payment::query()->where('customer_id', $payment->customer_id)->count(),
            ], JSON_THROW_ON_ERROR));
            $result = $this->structuredResult($response);
            $payment->update(['ai_anomaly' => [
                'available' => true,
                'provider' => 'Gemini',
                'model' => 'gemini-3.5-flash-lite',
                'analyzed_at' => now(),
                'requires_admin_review' => ($result['risk_score'] ?? 0) >= 70,
                'result' => $result,
            ]]);
        } catch (\Throwable $exception) {
            Log::warning('AI payment anomaly analysis unavailable.', ['payment_id' => $payment->getKey(), 'exception' => $exception::class]);
        }
    }

    private function candidates(ServiceRequest $request): array
    {
        return Artisan::query()
            ->where('verification_status', VerificationStatus::VERIFIED->value)
            ->where('service_offerings', 'elemMatch', [
                'service_reference' => $request->service_id,
                'is_active' => true,
            ])
            ->get()
            ->mapWithKeys(fn(Artisan $profile) => [$profile->getKey() => [
                'artisan_id' => $profile->getKey(),
                'experience_years' => (int) $profile->experience_years,
                'service_areas' => $profile->service_areas ?? [],
                'accepting_requests' => (bool) data_get($profile->availability, 'accepting_requests', false),
            ]])->all();
    }

    private function fallback(array $candidates): array
    {
        return collect($candidates)->sortByDesc(fn(array $candidate) => ($candidate['accepting_requests'] ? 100 : 0) + $candidate['experience_years'])
            ->take(10)->map(fn(array $candidate) => ['artisan_id' => $candidate['artisan_id'], 'reason' => 'Verified artisan matched by service, availability, and experience.', 'confidence_score' => null])->values()->all();
    }

    private function isConfigured(): bool
    {
        return filled(config('ai.providers.gemini.key'));
    }

    private function structuredResult(mixed $response): array
    {
        if (! $response instanceof StructuredAgentResponse) {
            throw new UnexpectedValueException('The AI agent did not return structured output.');
        }

        return $response->toArray();
    }
}
