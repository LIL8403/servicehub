<?php

namespace App\Services;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class CatalogService
{
    public function uniqueSlug(string $name, string $modelClass, ?Model $except = null): string
    {
        $base = Str::slug($name) ?: 'service';
        $slug = $base;
        $suffix = 2;

        while ($this->slugExists($slug, $modelClass, $except)) {
            $slug = "{$base}-{$suffix}";
            $suffix++;
        }

        return $slug;
    }

    private function slugExists(string $slug, string $modelClass, ?Model $except): bool
    {
        $query = $modelClass::query()->where('slug', $slug);

        if ($except !== null) {
            $query->where('_id', '!=', $except->getKey());
        }

        return $query->exists();
    }
}
