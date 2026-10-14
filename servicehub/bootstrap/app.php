<?php

use App\Http\Middleware\EnsureActiveAccount;
use App\Http\Middleware\RequirePermission;
use App\Http\Middleware\RequireRole;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__ . '/../routes/web.php',
        api: __DIR__ . '/../routes/api.php',
        commands: __DIR__ . '/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->redirectGuestsTo(function ($request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return null; // Return JSON 401 instead of redirecting
            }
            return route('login'); // Only used for web routes
        });

        $middleware->alias([
            'account.active' => EnsureActiveAccount::class,
            'permission' => RequirePermission::class,
            'role' => RequireRole::class,
            'verified' => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
        ]);

        $middleware->prepend(\Bilfeldt\CorrelationId\Middleware\CorrelationIdMiddleware::class);
        $middleware->prepend(\Bilfeldt\CorrelationId\Middleware\ClientRequestIdMiddleware::class);

        $middleware->alias([
            'account.active' => EnsureActiveAccount::class,
            'permission' => RequirePermission::class,
            'role' => RequireRole::class,
            'verified' => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn(Request $request) => $request->is('api/*'),
        );

        $exceptions->render(function (\Throwable $e, Request $request) {
            if ($e instanceof \Illuminate\Http\Exceptions\HttpResponseException) {
                return $e->getResponse();
            }

            if ($e instanceof \Illuminate\Http\Exceptions\ThrottleRequestsException) {
                return null;
            }

            if (! $request->is('api/*')) {
                return null;
            }

            $status = match (true) {
                $e instanceof \Illuminate\Validation\ValidationException => 422,
                $e instanceof \Illuminate\Auth\AuthenticationException => 401,
                $e instanceof \Illuminate\Auth\Access\AuthorizationException => 403,
                $e instanceof \Symfony\Component\HttpKernel\Exception\NotFoundHttpException => 404,
                $e instanceof \Symfony\Component\HttpKernel\Exception\HttpExceptionInterface => $e->getStatusCode(),
                default => 500,
            };

            $code = match (true) {
                $e instanceof \Illuminate\Validation\ValidationException => 'VALIDATION_ERROR',
                $e instanceof \Illuminate\Auth\AuthenticationException => 'UNAUTHENTICATED',
                $e instanceof \Illuminate\Auth\Access\AuthorizationException => 'FORBIDDEN',
                $e instanceof \Symfony\Component\HttpKernel\Exception\NotFoundHttpException => 'NOT_FOUND',
                $e instanceof \App\Exceptions\RefundNotSupportedException => 'REFUND_NOT_SUPPORTED',
                default => 'INTERNAL_ERROR',
            };

            $message = app()->environment('production')
                ? 'An error occurred. Please try again.'
                : $e->getMessage();

            $errors = $e instanceof \Illuminate\Validation\ValidationException
                ? $e->errors()
                : null;

            return response()->json([
                'success' => false,
                'message' => $message,           // Laravel standard
                'errors' => $errors,             // Laravel standard (for assertJsonValidationErrors)
                'error' => [                     // Your custom format
                    'code' => $code,
                    'message' => $message,
                    'details' => $errors,
                ],
                'request_id' => $request->header('X-Request-ID') ?? $request->header('X-Correlation-ID'),
            ], $status);
        });
    })
    ->create();
