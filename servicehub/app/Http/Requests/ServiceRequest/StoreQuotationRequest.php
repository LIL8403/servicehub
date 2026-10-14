<?php

namespace App\Http\Requests\ServiceRequest;

use Illuminate\Foundation\Http\FormRequest;

class StoreQuotationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            // Accept both spellings during the transition. New
            // submissions use `labor_amount`; older clients may
            // still send `labour_amount`.
            'labor_amount'  => ['nullable', 'numeric', 'min:0', 'max:100000000'],
            'labour_amount' => ['nullable', 'numeric', 'min:0', 'max:100000000'],
            'currency'      => ['required', 'string', 'size:3', 'in:XAF'],
            'scope'         => ['required', 'string', 'min:10', 'max:5000'],
            'valid_until'   => ['required', 'date', 'after:now'],
            'notes'         => ['nullable', 'string', 'max:1000'],
        ];
    }

    /**
     * Normalize to a single key before validation runs, so the
     * service layer always receives `labor_amount` regardless of
     * which spelling the client sent.
     */
    protected function prepareForValidation(): void
    {
        $labor = $this->input('labor_amount') ?? $this->input('labour_amount');

        if ($labor !== null) {
            $this->merge(['labor_amount' => $labor]);
        }

        if ($labor === null) {
            // Force a clear validation error on the canonical key.
            $this->merge(['labor_amount' => null]);
        }
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            if ($this->input('labor_amount') === null) {
                $validator->errors()->add(
                    'labor_amount',
                    'The labor amount field is required.',
                );
            }
        });
    }
}