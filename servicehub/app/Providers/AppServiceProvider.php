<?php

namespace App\Providers;

use App\Contracts\Payments\CamPayGateway;
use App\Models\PersonalAccessToken;
use App\Models\User;
use App\Services\Payments\CamPayHttpGateway;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Laravel\Sanctum\Sanctum;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(CamPayGateway::class, CamPayHttpGateway::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Sanctum::usePersonalAccessTokenModel(PersonalAccessToken::class);
        ResetPassword::createUrlUsing(fn (User $user, string $token) => rtrim(config('app.frontend_url'), '/').'/reset-password?token='.urlencode($token).'&email='.urlencode($user->email));

        RateLimiter::for('auth', fn (Request $request) => [
            $this->limit(config('api.auth_rate_limit'), 'auth:identity:'.$this->loginIdentity($request)),
            $this->limit(config('api.auth_ip_rate_limit'), 'auth:ip:'.$request->ip()),
        ]);
        RateLimiter::for('ai', fn (Request $request) => $this->limit(
            config('api.ai_rate_limit'),
            'ai:'.$this->userOrIp($request),
        ));
        RateLimiter::for('payments', fn (Request $request) => $this->limit(
            config('api.payment_rate_limit'),
            'payments:'.$this->userOrIp($request),
        ));
        RateLimiter::for('verification', fn (Request $request) => $this->limit(
            config('api.verification_rate_limit'),
            'verification:'.$this->userOrIp($request),
        ));
    }

    private function limit(int $maxAttempts, string $key): Limit
    {
        return Limit::perMinute(max(1, $maxAttempts))
            ->by($key)
            ->response(fn (Request $request, array $headers) => response()->json([
                'message' => 'Too many requests. Please try again later.',
            ], 429, [...$headers, 'Retry-After' => '60']));
    }

    private function loginIdentity(Request $request): string
    {
        $email = mb_strtolower(trim((string) $request->input('email')));

        return hash('sha256', $email !== '' ? $email : $request->ip());
    }

    private function userOrIp(Request $request): string
    {
        return $request->user()?->getKey() ?? $request->ip();
    }
}
