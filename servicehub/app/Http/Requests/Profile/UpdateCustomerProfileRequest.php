<?php

namespace App\Http\Requests\Profile;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCustomerProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'min:2', 'max:100'],
            'phone' => ['sometimes', 'required', 'string', 'max:20', 'unique:users,phone,'.$this->user()->getKey()],
            'default_location' => ['nullable', 'array:label,type,coordinates'],
            'default_location.label' => ['nullable', 'string', 'max:255'],
            'default_location.type' => ['required_with:default_location', 'in:Point'],
            'default_location.coordinates' => ['required_with:default_location', 'array', 'size:2'],
            'default_location.coordinates.0' => ['numeric', 'between:-180,180'],
            'default_location.coordinates.1' => ['numeric', 'between:-90,90'],
            'preferences' => ['nullable', 'array'],
        ];
    }
}
