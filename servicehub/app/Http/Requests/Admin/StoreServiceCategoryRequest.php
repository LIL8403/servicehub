<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class StoreServiceCategoryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return ['name' => ['required', 'string', 'min:2', 'max:100', 'unique:service_categories,name'], 'description' => ['nullable', 'string', 'max:2000'], 'icon' => ['nullable', 'string', 'max:100'], 'is_active' => ['sometimes', 'boolean']];
    }
}
