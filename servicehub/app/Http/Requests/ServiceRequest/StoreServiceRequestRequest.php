<?php

namespace App\Http\Requests\ServiceRequest;

use Illuminate\Foundation\Http\FormRequest;


class StoreServiceRequestRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'service_id' => ['required', 'string'],
            'description' => ['required', 'string', 'min:10', 'max:5000'],
            'ai_assist_enabled' => ['sometimes', 'boolean'],
            'urgency' => ['nullable', 'string', 'in:low,medium,high'],
            'address' => ['nullable', 'string', 'min:3', 'max:500', 'required_without:location'],
            'location' => ['nullable', 'array:label,type,coordinates', 'required_without:address'],
            'location.label' => ['required_with:location', 'string', 'max:255'],
            'location.type' => ['required_with:location', 'in:Point'],
            'location.coordinates' => ['required_with:location', 'array', 'size:2'],
            'location.coordinates.0' => ['required_with:location', 'numeric', 'between:-180,180'],
            'location.coordinates.1' => ['required_with:location', 'numeric', 'between:-90,90'],
            'images' => ['nullable', 'array', 'max:5'],
            'images.*' => [
                'file',
                'image',
                'mimetypes:image/jpeg,image/png,image/webp',
                'dimensions:max_width=4096,max_height=4096',
                'max:5120',
            ],
            'preferred_schedule' => ['nullable', 'array:date,window,notes'],
            'preferred_schedule.date' => ['nullable', 'date', 'after_or_equal:today'],
            'preferred_schedule.window' => ['nullable', 'string', 'max:100'],
            'preferred_schedule.notes' => ['nullable', 'string', 'max:500'],
        ];
    }

    protected function prepareForValidation(): void
    {
        // Trim the incoming address if present.
        if (is_string($this->input('address'))) {
            $this->merge(['address' => trim($this->input('address'))]);
        }

        // Coerce GeoJSON coordinates to floats before validation.
        //
        // Why: multipart form-data field values are always strings, so
        // `location[coordinates][0]` arrives as "11.4761718". Laravel's
        // `numeric` rule accepts numeric strings but does NOT cast them.
        // MongoDB's 2dsphere index rejects string coordinates with
        // "Can't extract geo keys", which 500s the whole submission.
        //
        // Casting here ensures every consumer of validated() gets
        // proper floats, regardless of JSON vs multipart on the wire.
        $location = $this->input('location');
        if (
            is_array($location)
            && isset($location['coordinates'])
            && is_array($location['coordinates'])
        ) {
            $location['coordinates'] = array_map(
                static fn($value) => is_numeric($value) ? (float) $value : $value,
                $location['coordinates'],
            );
            $this->merge(['location' => $location]);
        }
    }
}
