<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ResolveDisputeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'decision' => ['required', 'string', Rule::in(['refund_customer', 'release_artisan', 'split_resolution', 'hold'])],
            'customer_refund_amount' => ['required', 'numeric', 'min:0'],
            'artisan_gross_release' => ['required', 'numeric', 'min:0'],
            'reason' => ['required', 'string', 'min:5', 'max:2000'],
            'resolution_reference' => ['required', 'string', 'regex:/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i'],
        ];
    }
}
