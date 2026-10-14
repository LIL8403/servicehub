<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Service;
use App\Models\ServiceCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CatalogController extends Controller
{
    public function categories(): JsonResponse
    {
        return response()->json(['categories' => ServiceCategory::query()->where('is_active', true)->orderBy('name')->get()]);
    }

    public function services(Request $request): JsonResponse
    {
        $validated = $request->validate(['category' => ['nullable', 'string', 'max:120']]);
        $query = Service::query()->where('is_active', true)->orderBy('name');

        if (isset($validated['category'])) {
            $category = ServiceCategory::query()->where('slug', $validated['category'])->where('is_active', true)->firstOrFail();
            $query->where('service_category_id', $category->getKey());
        }

        return response()->json(['services' => $query->with('category')->get()]);
    }
}
