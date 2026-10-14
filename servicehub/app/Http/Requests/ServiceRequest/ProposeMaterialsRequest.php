<?php

namespace App\Http\Requests\ServiceRequest;

use Illuminate\Foundation\Http\FormRequest;

class ProposeMaterialsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'materials' => ['required', 'array', 'min:1', 'max:50'],
            'materials.*.name' => ['required', 'string', 'min:2', 'max:255'],
            'materials.*.quantity' => ['required', 'numeric', 'gt:0', 'max:100000'],
            'materials.*.unit' => ['required', 'string', 'max:50'],
            'materials.*.unit_cost' => ['required', 'numeric', 'min:0', 'max:100000000'],
            'materials.*.notes' => ['nullable', 'string', 'max:500'],
        ];
    }
}
