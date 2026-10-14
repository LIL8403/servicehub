<?php

namespace App\Http\Requests\Profile;

use Illuminate\Foundation\Http\FormRequest;

class UpdateArtisanProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'professional_title' => ['sometimes', 'required', 'string', 'min:2', 'max:100'],
            'bio' => ['nullable', 'string', 'max:2000'],
            'experience_years' => ['sometimes', 'required', 'integer', 'min:0', 'max:60'],
            'service_location' => ['nullable', 'array:type,coordinates'],
            'service_location.type' => ['required_with:service_location', 'in:Point'],
            'service_location.coordinates' => ['required_with:service_location', 'array', 'size:2'],
            'service_location.coordinates.0' => ['numeric', 'between:-180,180'],
            'service_location.coordinates.1' => ['numeric', 'between:-90,90'],
            'service_areas' => ['nullable', 'array', 'max:20'],
            'service_areas.*' => ['string', 'max:255'],
            'availability' => ['nullable', 'array'],
            'payout_phone' => ['sometimes', 'nullable', 'string', 'regex:/^2376\d{8}$/'],

            // Extended fields for the profile editor screen
            'service_offerings' => ['sometimes', 'array', 'max:20'],
            'service_offerings.*.service_reference' => [
                'required_with:service_offerings',
                'string',
                'max:100',
            ],
            'service_offerings.*.is_active' => [
                'required_with:service_offerings',
                'boolean',
            ],

            'languages' => ['sometimes', 'array', 'max:5'],
            'languages.*' => ['string', 'in:english,french'],
        ];
    }
}
