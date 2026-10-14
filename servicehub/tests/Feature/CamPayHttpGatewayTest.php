<?php

use App\Services\Payments\CamPayHttpGateway;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;

it('uses CamPay Token authentication when checking a normal payment status', function () {
    Config::set('services.campay.base_url', 'https://campay.test/api');
    Config::set('services.campay.username', 'demo-user');
    Config::set('services.campay.password', 'demo-password');
    Http::fake([
        'https://campay.test/api/token/' => Http::response(['token' => 'access-token'], 200),
        'https://campay.test/api/transaction/collection-reference/' => Http::response(['reference' => 'collection-reference', 'status' => 'SUCCESSFUL'], 200),
    ]);

    $result = app(CamPayHttpGateway::class)->transactionStatus('collection-reference');

    expect($result['status'])->toBe('SUCCESSFUL');
    Http::assertSent(fn (Request $request) => $request->url() === 'https://campay.test/api/transaction/collection-reference/'
        && $request->hasHeader('Authorization', 'Token access-token'));
});

it('uses CamPay Token authentication when collecting a normal payment', function () {
    Config::set('services.campay.base_url', 'https://campay.test/api');
    Config::set('services.campay.username', 'demo-user');
    Config::set('services.campay.password', 'demo-password');
    Http::fake([
        'https://campay.test/api/token/' => Http::response(['token' => 'access-token'], 200),
        'https://campay.test/api/collect/' => Http::response(['reference' => 'collection-reference', 'status' => 'PENDING'], 200),
    ]);

    $result = app(CamPayHttpGateway::class)->initiateCollection(20000, '237677000000', 'ServiceHUB test collection', 'SH-test');

    expect($result['status'])->toBe('PENDING');
    Http::assertSent(fn (Request $request) => $request->url() === 'https://campay.test/api/collect/'
        && $request->hasHeader('Authorization', 'Token access-token'));
});
