<?php

namespace App\Services\Payments;

use App\Contracts\Payments\CamPayGateway;
use Illuminate\Support\Str;
use RuntimeException;

class SimulatedCamPayGateway implements CamPayGateway
{
    public function initiateCollection(int|float $amount, string $phone, string $description, string $externalReference, string $provider): array
    {
        throw new RuntimeException('The simulated provider cannot collect normal payments.');
    }

    public function transactionStatus(string $reference): array
    {
        throw new RuntimeException('The simulated provider cannot reconcile normal payments.');
    }

    public function initiatePayout(int|float $amount, string $phone, string $description, string $externalReference): array
    {
        return $this->result('disburse', $externalReference, $amount);
    }

    public function initiateRefund(int|float $amount, string $collectionReference, string $externalReference): array
    {
        return $this->result('refund', $externalReference, $amount, $collectionReference);
    }

    /** @return array{reference:string,status:string,raw:array<string,mixed>} */
    private function result(string $operation, string $externalReference, int|float $amount, ?string $collectionReference = null): array
    {
        $failureMode = strtolower((string) config('services.campay.simulation_fail_on'));
        $failed = in_array($failureMode, [$operation, 'both'], true);
        $reference = 'SIM-'.Str::uuid();

        return [
            'reference' => $reference,
            'status' => $failed ? 'FAILED' : 'SUCCESSFUL',
            'raw' => [
                'reference' => $reference,
                'status' => $failed ? 'FAILED' : 'SUCCESSFUL',
                'amount' => $amount,
                'external_reference' => $externalReference,
                'collection_reference' => $collectionReference,
                'operation' => $operation,
                'is_simulated' => true,
                'notice' => 'SIMULATED — no real funds moved.',
            ],
        ];
    }
}