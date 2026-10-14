<?php

namespace App\Http\Requests\ServiceRequest;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class UpdateServiceRequestRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'description' => ['sometimes', 'string', 'min:10', 'max:5000'],
            'address' => ['sometimes', 'string', 'min:3', 'max:500'],
            'location' => ['sometimes', 'array:label,type,coordinates'],
            'location.label' => ['required_with:location', 'string', 'max:255'],
            'location.type' => ['required_with:location', 'in:Point'],
            'location.coordinates' => ['required_with:location', 'array', 'size:2'],
            'location.coordinates.0' => ['required_with:location', 'numeric', 'between:-180,180'],
            'location.coordinates.1' => ['required_with:location', 'numeric', 'between:-90,90'],
            'preferred_schedule' => ['sometimes', 'nullable', 'array:date,window,notes'],
            'preferred_schedule.date' => ['nullable', 'date', 'after_or_equal:today'],
            'preferred_schedule.window' => ['nullable', 'string', 'max:100'],
            'preferred_schedule.notes' => ['nullable', 'string', 'max:500'],
        ];
    }

    protected function prepareForValidation(): void
    {
        if (is_string($this->input('address'))) {
            $this->merge(['address' => trim($this->input('address'))]);
        }
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            if (! $this->hasAny(['description', 'address', 'location', 'preferred_schedule'])) {
                $validator->errors()->add('request', 'Provide at least one request detail to update.');
            }
        });
    }
}
