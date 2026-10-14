<?php

namespace App\Http\Requests\User;

use Illuminate\Foundation\Http\FormRequest;

class BecomeArtisanRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'professional_description' => ['required', 'string', 'min:10', 'max:2000'],
            'experience_years' => ['required', 'integer', 'min:0', 'max:60'],
            'languages' => ['nullable', 'array', 'max:10'],
            'languages.*' => ['string', 'max:50'],
            'service_areas' => ['nullable', 'array', 'max:20'],
            'service_areas.*' => ['string', 'max:255'],
        ];
    }
}
