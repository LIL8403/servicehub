<?php

namespace App\Http\Requests\Dispute;

use Illuminate\Foundation\Http\FormRequest;

class OpenDisputeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'reason' => ['required', 'string', 'min:3', 'max:120'],
            'description' => ['required', 'string', 'min:10', 'max:2000'],
            'urgency' => ['nullable', 'string', 'in:low,medium,high'],
            'evidence' => ['nullable', 'array', 'max:5'],
            'evidence.*' => ['nullable'],
        ];
    }
}