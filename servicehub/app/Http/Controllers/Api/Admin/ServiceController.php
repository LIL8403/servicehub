<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreServiceRequest;
use App\Http\Requests\Admin\UpdateServiceRequest;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Services\CatalogService;
use Illuminate\Http\JsonResponse;

class ServiceController extends Controller
{
    public function __construct(private readonly CatalogService $catalogService) {}

    public function index(): JsonResponse
    {
        return response()->json(['services' => Service::query()->with('category')->orderBy('name')->get()]);
    }

    public function store(StoreServiceRequest $request): JsonResponse
    {
        $data = $request->validated();
        ServiceCategory::query()->findOrFail($data['service_category_id']);
        $data['slug'] = $this->catalogService->uniqueSlug($data['name'], Service::class);
        $service = Service::create($data);

        return response()->json(['service' => $service->load('category')], 201);
    }

    public function update(UpdateServiceRequest $request, Service $service): JsonResponse
    {
        $data = $request->validated();

        if (array_key_exists('service_category_id', $data)) {
            ServiceCategory::query()->findOrFail($data['service_category_id']);
        }

        if (array_key_exists('name', $data)) {
            $data['slug'] = $this->catalogService->uniqueSlug($data['name'], Service::class, $service);
        }

        $service->update($data);

        return response()->json(['service' => $service->fresh()->load('category')]);
    }

    public function destroy(Service $service): JsonResponse
    {
        $service->delete();

        return response()->json(status: 204);
    }
}
