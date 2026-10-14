<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CamPayWebhookController extends Controller
{
    public function __construct(private readonly PaymentService $payments) {}

    public function __invoke(Request $request): JsonResponse
    {
        $secret = config('services.campay.webhook_secret');
        abort_unless(is_string($secret) && $secret !== '', 503, 'CamPay webhook verification is not configured.');

        $data = $request->validate([
            'reference' => ['required', 'string', 'max:255'],
            'status' => ['required', 'string', 'in:PENDING,SUCCESSFUL,FAILED,pending,successful,failed'],
            'signature' => ['required', 'string'],
            'external_reference' => ['required', 'string', 'max:255'],
            'amount' => ['required', 'numeric', 'min:0'],
            'currency' => ['required', 'string', 'in:XAF'],
            'operator' => ['nullable', 'string', 'max:64'],
            'code' => ['nullable', 'string', 'max:255'],
            'operator_reference' => ['nullable', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:1000'],
        ]);
        abort_unless($this->validSignature($data['signature'], $secret), 401, 'Invalid CamPay webhook signature.');

        unset($data['signature']);
        $payment = $this->payments->reconcileWebhook($data['reference'], [
            'reference' => $data['reference'],
            'status' => $data['status'],
            'raw' => $data,
        ]);
        $payout = $payment ? null : $this->payments->reconcilePayoutWebhook($data['reference'], [
            'reference' => $data['reference'],
            'status' => $data['status'],
            'raw' => $data,
        ]);

        return response()->json(['received' => true, 'payment_found' => $payment !== null, 'payout_found' => $payout !== null]);
    }

    private function validSignature(string $jwt, string $secret): bool
    {
        $parts = explode('.', $jwt);
        if (count($parts) !== 3) {
            return false;
        }
        $header = json_decode($this->base64UrlDecode($parts[0]), true);
        if (! is_array($header) || ($header['alg'] ?? null) !== 'HS256') {
            return false;
        }

        $expected = rtrim(strtr(base64_encode(hash_hmac('sha256', $parts[0].'.'.$parts[1], $secret, true)), '+/', '-_'), '=');

        return hash_equals($expected, $parts[2]);
    }

    private function base64UrlDecode(string $value): string
    {
        $padded = str_pad(strtr($value, '-_', '+/'), strlen($value) % 4 === 0 ? strlen($value) : strlen($value) + 4 - strlen($value) % 4, '=', STR_PAD_RIGHT);

        return (string) base64_decode($padded, true);
    }
}
