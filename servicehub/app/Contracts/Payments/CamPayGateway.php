<?php

namespace App\Contracts\Payments;

interface CamPayGateway
{
    /**
     * Initiates a collection request against CamPay.
     *
     * @param  string  $provider  The mobile money network: 'mtn' or 'orange'.
     * @return array{reference:string,status:string,raw:array<string,mixed>}
     */
    public function initiateCollection(int|float $amount, string $phone, string $description, string $externalReference, string $provider): array;

    /** @return array{reference:string,status:string,raw:array<string,mixed>} */
    public function transactionStatus(string $reference): array;

    /** @return array{reference:string,status:string,raw:array<string,mixed>} */
    public function initiatePayout(int|float $amount, string $phone, string $description, string $externalReference): array;

    /** @return array{reference:string,status:string,raw:array<string,mixed>} */
    public function initiateRefund(int|float $amount, string $collectionReference, string $externalReference): array;
}