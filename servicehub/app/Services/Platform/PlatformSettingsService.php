<?php

namespace App\Services\Platform;

use App\Models\PlatformSetting;
use App\Services\AuditLogService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Validation\ValidationException;

class PlatformSettingsService
{
    public const DEFAULT_COMMISSION_RATE = 0.07;

    private const COMMISSION_CACHE_KEY = 'platform-settings:commission-rate';

    public function __construct(private readonly AuditLogService $auditLogs) {}

    public function getCommissionRate(): float
    {
        return (float) Cache::remember(self::COMMISSION_CACHE_KEY, now()->addSeconds(60), function (): float {
            return (float) (PlatformSetting::query()->where('key', 'commission_rate')->value('value') ?? self::DEFAULT_COMMISSION_RATE);
        });
    }

    public function getCommissionRateSnapshot(): float
    {
        return $this->getCommissionRate();
    }

    public function updateCommissionRate(float $rate, string $adminId, string $reason = ''): void
    {
        $this->assertValidCommissionRate($rate);
        $setting = PlatformSetting::query()->where('key', 'commission_rate')->first();
        $oldRate = $setting ? (float) $setting->value : self::DEFAULT_COMMISSION_RATE;

        if ($setting) {
            $setting->update([
                'value' => $rate,
                'description' => 'Platform commission retained from artisan earnings',
                'updated_by' => $adminId,
            ]);
        } else {
            PlatformSetting::create([
                'key' => 'commission_rate',
                'value' => $rate,
                'description' => 'Platform commission retained from artisan earnings',
                'updated_by' => $adminId,
            ]);
        }

        Cache::forget(self::COMMISSION_CACHE_KEY);
        $this->auditLogs->record('platform.commission_rate_updated', $adminId, 'platform_setting', 'commission_rate', [
            'old_rate' => $oldRate,
            'new_rate' => $rate,
            'reason' => $reason,
        ]);
    }

    private function assertValidCommissionRate(float $rate): void
    {
        if (! is_finite($rate) || $rate < 0 || $rate > 0.30) {
            throw ValidationException::withMessages(['rate' => ['Commission rate must be between 0.00 and 0.30.']]);
        }
    }
}
