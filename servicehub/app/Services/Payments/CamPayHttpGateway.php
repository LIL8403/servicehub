<?php

namespace App\Services\Payments;

use App\Contracts\Payments\CamPayGateway;
use App\Exceptions\RefundNotSupportedException;
use Illuminate\Http\Client\Factory as HttpFactory;
use Illuminate\Http\Client\PendingRequest;
use RuntimeException;

class CamPayHttpGateway implements CamPayGateway
{
    public function __construct(private readonly HttpFactory $http) {}

    public function initiateCollection(int|float $amount, string $phone, string $description, string $externalReference, string $provider): array
    {
        $baseUrl = rtrim((string) config('services.campay.base_url'), '/');
        $username = config('services.campay.username');
        $password = config('services.campay.password');

        if ($baseUrl === '' || ! $username || ! $password) {
            throw new RuntimeException('CamPay is not configured.');
        }

        $network = strtoupper($provider) === 'ORANGE' ? 'ORANGE' : 'MTN';

        $tokenResponse = $this->http->acceptJson()->post("{$baseUrl}/token/", [
            'username' => $username,
            'password' => $password,
        ])->throw()->json();

        $token = $tokenResponse['token'] ?? null;

        if (! is_string($token) || $token === '') {
            throw new RuntimeException('CamPay did not return an access token.');
        }

        $response = $this->http->acceptJson()
            ->withHeaders(['Authorization' => 'Token ' . $token])
            ->post("{$baseUrl}/collect/", [
                'amount' => $amount,
                'currency' => 'XAF',
                'from' => $phone,
                'description' => $description,
                'external_reference' => $externalReference,
                'provider' => $network,
            ])->throw()->json();

        // CamPay's initial collection response does NOT include a
        // `status` field. It includes `reference`, and typically a
        // `code` or `message` that indicates acceptance. We consider
        // the initiation successful as long as we get a reference back.
        $reference = $response['reference'] ?? null;

        if (! is_string($reference) || $reference === '') {
            throw new RuntimeException(
                'CamPay returned an invalid collection response: '
                    . json_encode($response)
            );
        }

        // Derive a status string that the caller can interpret.
        // CamPay's own terminology varies; treat a 200 with a
        // reference as "PENDING" (the customer must still approve
        // on their phone). The webhook or reconcile step will move
        // the payment to HELD once approved.
        $status = strtoupper((string) (
            $response['status']
            ?? $response['code']
            ?? $response['message']
            ?? 'PENDING'
        ));

        // Normalise anything that signals success to the string the
        // caller's state machine recognises.
        if (in_array($status, ['SUCCESS', 'SUCCESSFUL', 'OK', 'PENDING'], true)) {
            $status = 'PENDING';
        }

        return [
            'reference' => $reference,
            'status' => $status,
            'raw' => $response,
        ];
    }

    public function transactionStatus(string $reference): array
    {
        $baseUrl = rtrim((string) config('services.campay.base_url'), '/');
        $response = $this->authenticatedClient()
            ->get("{$baseUrl}/transaction/{$reference}/")->throw()->json();

        if (! isset($response['reference'], $response['status'])) {
            throw new RuntimeException('CamPay returned an invalid transaction-status response.');
        }

        return ['reference' => (string) $response['reference'], 'status' => (string) $response['status'], 'raw' => $response];
    }

    public function initiatePayout(int|float $amount, string $phone, string $description, string $externalReference): array
    {
        $baseUrl = rtrim((string) config('services.campay.base_url'), '/');
        $response = $this->authenticatedClient()
            ->post("{$baseUrl}/withdraw/", [
                'amount' => $amount,
                'currency' => 'XAF',
                'to' => $phone,
                'description' => $description,
                'external_reference' => $externalReference,
            ])->throw()->json();

        if (! isset($response['reference'], $response['status'])) {
            throw new RuntimeException('CamPay returned an invalid payout response.');
        }

        return ['reference' => (string) $response['reference'], 'status' => (string) $response['status'], 'raw' => $response];
    }

    public function initiateRefund(int|float $amount, string $collectionReference, string $externalReference): array
    {
        throw new RefundNotSupportedException('CamPay does not document an automated refund endpoint. Use the explicitly simulated dispute path.');
    }

    private function accessToken(): string
    {
        $baseUrl = rtrim((string) config('services.campay.base_url'), '/');
        $username = config('services.campay.username');
        $password = config('services.campay.password');

        if ($baseUrl === '' || ! $username || ! $password) {
            throw new RuntimeException('CamPay is not configured.');
        }

        $response = $this->http->acceptJson()->post("{$baseUrl}/token/", ['username' => $username, 'password' => $password])->throw()->json();
        $token = $response['token'] ?? null;

        if (! is_string($token) || $token === '') {
            throw new RuntimeException('CamPay did not return an access token.');
        }

        return $token;
    }

    private function authenticatedClient(): PendingRequest
    {
        return $this->http->createPendingRequest()
            ->acceptJson()
            ->withHeaders(['Authorization' => 'Token ' . $this->accessToken()]);
    }
}
