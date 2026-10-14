<?php

namespace App\Http\Requests\Payment;

use Illuminate\Foundation\Http\FormRequest;

class InitiatePaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'phone' => ['required', 'string', 'regex:/^2376\d{8}$/'],
            'idempotency_key' => ['required', 'uuid'],
            'provider' => ['required', 'string', 'in:mtn,orange'],
        ];
    }
}
