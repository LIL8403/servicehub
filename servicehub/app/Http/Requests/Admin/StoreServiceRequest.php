<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class StoreServiceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return ['service_category_id' => ['required', 'string'], 'name' => ['required', 'string', 'min:2', 'max:100'], 'description' => ['nullable', 'string', 'max:2000'], 'is_active' => ['sometimes', 'boolean']];
    }
}
