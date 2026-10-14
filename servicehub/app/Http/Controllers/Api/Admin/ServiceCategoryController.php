<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreServiceCategoryRequest;
use App\Http\Requests\Admin\UpdateServiceCategoryRequest;
use App\Models\ServiceCategory;
use App\Services\CatalogService;
use Illuminate\Http\JsonResponse;

class ServiceCategoryController extends Controller
{
    public function __construct(private readonly CatalogService $catalogService) {}

    public function index(): JsonResponse
    {
        return response()->json([
            'categories' => ServiceCategory::query()
                ->with('services')
                ->orderBy('name')
                ->get(),
        ]);
    }

    public function store(StoreServiceCategoryRequest $request): JsonResponse
    {
        $data = $request->validated();
        $data['slug'] = $this->catalogService->uniqueSlug($data['name'], ServiceCategory::class);

        return response()->json(['category' => ServiceCategory::create($data)], 201);
    }

    public function update(UpdateServiceCategoryRequest $request, ServiceCategory $serviceCategory): JsonResponse
    {
        $data = $request->validated();

        if (array_key_exists('name', $data)) {
            $data['slug'] = $this->catalogService->uniqueSlug($data['name'], ServiceCategory::class, $serviceCategory);
        }

        $serviceCategory->update($data);

        return response()->json(['category' => $serviceCategory->fresh()]);
    }

    public function destroy(ServiceCategory $serviceCategory): JsonResponse
    {
        abort_if($serviceCategory->services()->exists(), 409, 'A category with services cannot be deleted.');
        $serviceCategory->delete();

        return response()->json(status: 204);
    }
}
