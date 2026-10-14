<?php

namespace App\Http\Requests\Admin;

use App\Enums\AccountStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateAccountStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'status' => ['required', Rule::enum(AccountStatus::class)],
            'reason' => ['required', 'string', 'min:5', 'max:500'],
        ];
    }
}
