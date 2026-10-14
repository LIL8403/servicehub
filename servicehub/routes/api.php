<?php

use App\Http\Controllers\Api\Admin\ArtisanVerificationController;
use App\Http\Controllers\Api\Admin\PlatformSettingsController;
use App\Http\Controllers\Api\Admin\ReportingController;
use App\Http\Controllers\Api\Admin\ServiceCategoryController;
use App\Http\Controllers\Api\Admin\ServiceController;
use App\Http\Controllers\Api\Admin\UserManagementController;
use App\Http\Controllers\Api\AiController;
use App\Http\Controllers\Api\ArtisanDiscoveryController;
use App\Http\Controllers\Api\ArtisanRequestController;
use App\Http\Controllers\Api\ArtisanServiceOfferingController;
use App\Http\Controllers\Api\Auth\AuthController;
use App\Http\Controllers\Api\CamPayWebhookController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\ConversationController;
use App\Http\Controllers\Api\DisputeController;
use App\Http\Controllers\Api\DisputeEvidenceController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\ServiceRequestController;
use App\Http\Controllers\Api\UserRoleController;
use App\Http\Controllers\Api\ArtisanEarningsController;
use Illuminate\Auth\Events\Verified;
use Illuminate\Foundation\Auth\EmailVerificationRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware(['auth:sanctum', 'account.active']);

Route::get('/service-categories', [CatalogController::class, 'categories']);
Route::get('/services', [CatalogController::class, 'services']);
Route::get('/artisans', [ArtisanDiscoveryController::class, 'index']);
Route::post('/webhooks/campay', CamPayWebhookController::class);

Route::middleware(['auth:sanctum', 'account.active'])->prefix('user')->group(function () {
    Route::get('/roles', [UserRoleController::class, 'roles']);
    Route::post('/switch-role', [UserRoleController::class, 'switchRole']);
    Route::post('/become-artisan', [UserRoleController::class, 'becomeArtisan']);
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::patch('/notifications/{notification}/read', [NotificationController::class, 'markRead']);
});

Route::middleware(['auth:sanctum', 'account.active', 'role:customer', 'throttle:ai'])->group(function () {
    Route::post('/ai/recommend', [AiController::class, 'recommend']);
    Route::post('/ai/understand-draft', [AiController::class, 'understandDraft']);
    Route::post('/ai/service-requests/{serviceRequest}/understand', [AiController::class, 'understand']);
    Route::post('/ai/service-requests/{serviceRequest}/quotation/analyze', [AiController::class, 'analyzeQuotation']);
});

Route::middleware(['auth:sanctum', 'account.active', 'role:customer'])->prefix('customer')->group(function () {
    Route::get('/profile', [ProfileController::class, 'customer']);
    Route::patch('/profile', [ProfileController::class, 'updateCustomer']);
    Route::post('/profile/photo', [ProfileController::class, 'storePhoto']);
    Route::get('/profile/photo', [ProfileController::class, 'downloadPhoto']);
    Route::delete('/profile/photo', [ProfileController::class, 'destroyPhoto']);
    Route::get('/service-requests', [ServiceRequestController::class, 'index']);
    Route::post('/service-requests', [ServiceRequestController::class, 'store']);
    Route::get('/service-requests/{serviceRequest}/tracking', [ServiceRequestController::class, 'tracking']);
    Route::get('/service-requests/{serviceRequest}', [ServiceRequestController::class, 'show']);
    Route::patch('/service-requests/{serviceRequest}', [ServiceRequestController::class, 'update']);
    Route::post('/service-requests/{serviceRequest}/cancel', [ServiceRequestController::class, 'cancel']);
    Route::get('/service-requests/{serviceRequest}/images/{imageId}', [ServiceRequestController::class, 'downloadImage']);
    Route::post('/service-requests/{serviceRequest}/select-artisan', [ServiceRequestController::class, 'selectArtisan']);
    Route::post('/service-requests/{serviceRequest}/change-artisan', [ServiceRequestController::class, 'changeArtisan']);
    Route::post('/service-requests/{serviceRequest}/retry-matching', [ServiceRequestController::class, 'retryMatching']);
    Route::get('/service-requests/{serviceRequest}/eligible-artisans', [ServiceRequestController::class, 'eligibleArtisans']);
    Route::post('/service-requests/{serviceRequest}/inspection', [ServiceRequestController::class, 'scheduleInspection']);
    Route::post('/service-requests/{serviceRequest}/quotation/accept', [ServiceRequestController::class, 'acceptQuotation']);
    Route::post('/service-requests/{serviceRequest}/quotation/reject', [ServiceRequestController::class, 'rejectQuotation']);
    Route::post('/service-requests/{serviceRequest}/materials/approve', [ServiceRequestController::class, 'approveMaterials']);
    Route::post('/service-requests/{serviceRequest}/completion/confirm', [ServiceRequestController::class, 'confirmCompletion']);
    Route::post('/service-requests/{serviceRequest}/payout/retry', [ServiceRequestController::class, 'retryPayout']);
    Route::post('/service-requests/{serviceRequest}/reviews', [ReviewController::class, 'store']);
    Route::get('/service-requests/{serviceRequest}/conversation', [ConversationController::class, 'show']);
    Route::get('/conversations/{conversation}/messages', [ConversationController::class, 'messages']);
    Route::get('/conversations', [\App\Http\Controllers\Api\CustomerConversationController::class, 'index']);
    Route::post('/conversations/{conversation}/messages', [ConversationController::class, 'store']);
    Route::get('/conversations/{conversation}/messages/{message}/attachments/{attachmentId}', [ConversationController::class, 'download']);
    Route::get('/disputes', [DisputeController::class, 'customerIndex']);
    Route::post('/service-requests/{serviceRequest}/disputes', [DisputeController::class, 'open']);
    Route::post('/disputes/evidence', [DisputeEvidenceController::class, 'store']);
    Route::post('/disputes/{dispute}/evidence', [DisputeController::class, 'addEvidence']);
    Route::post('/service-requests/{serviceRequest}/payments', [PaymentController::class, 'initiate'])->middleware(['verified', 'throttle:payments']);
    Route::get('/payments', [\App\Http\Controllers\Api\CustomerPaymentController::class, 'index']);
    Route::post('/payments/{payment}/reconcile', [PaymentController::class, 'reconcile'])->middleware('throttle:payments');
});

Route::middleware(['auth:sanctum', 'account.active', 'role:artisan'])->prefix('artisan')->group(function () {
    Route::get('/verification', [ArtisanVerificationController::class, 'show']);
    Route::patch('/verification/identity', [ArtisanVerificationController::class, 'saveIdentity']);
    Route::post('/verification/identity/document', [ArtisanVerificationController::class, 'uploadIdentityDocument']);
    Route::post('/verification/selfie', [ArtisanVerificationController::class, 'uploadSelfie']);
    Route::post('/verification/documents', [ArtisanVerificationController::class, 'uploadSupportingDocument']);
    Route::get('/verification/documents/{documentId}/download', [ArtisanVerificationController::class, 'downloadSupportingDocument']);
    Route::delete('/verification/documents/{documentId}', [ArtisanVerificationController::class, 'deleteSupportingDocument']);
    Route::post('/verification/submit', [ArtisanVerificationController::class, 'submit']);
    Route::get('/verification/download/{slot}', [ArtisanVerificationController::class, 'download']);
    Route::get('/profile', [ProfileController::class, 'artisan']);
    Route::get('/service-requests', [ArtisanRequestController::class, 'index']);
    Route::get('/service-requests/{serviceRequest}', [ArtisanRequestController::class, 'show']);
    Route::post('/service-requests/{serviceRequest}/approve', [ArtisanRequestController::class, 'approve']);
    Route::post('/service-requests/{serviceRequest}/decline', [ArtisanRequestController::class, 'decline']);
    Route::patch('/profile', [ProfileController::class, 'updateArtisan'])->middleware('verified');
    Route::get('/service-offerings', [ArtisanServiceOfferingController::class, 'index']);
    Route::post('/service-offerings', [ArtisanServiceOfferingController::class, 'store']);
    Route::patch('/service-offerings/{offeringId}', [ArtisanServiceOfferingController::class, 'update']);
    Route::delete('/service-offerings/{offeringId}', [ArtisanServiceOfferingController::class, 'destroy']);
    Route::post('/service-requests/{serviceRequest}/inspection/complete', [ArtisanRequestController::class, 'completeInspection']);
    Route::get('/service-requests/{serviceRequest}/images/{imageId}', [ArtisanRequestController::class, 'downloadImage']);
    Route::post('/service-requests/{serviceRequest}/quotation', [ArtisanRequestController::class, 'submitQuotation']);
    Route::post('/service-requests/{serviceRequest}/materials', [ArtisanRequestController::class, 'proposeMaterials']);
    Route::post('/service-requests/{serviceRequest}/start', [ArtisanRequestController::class, 'start']);
    Route::post('/service-requests/{serviceRequest}/completion', [ArtisanRequestController::class, 'reportCompletion']);
    Route::get('/earnings/summary', [ArtisanEarningsController::class, 'summary']);
    Route::get('/payouts', [ArtisanEarningsController::class, 'payouts']);
    Route::get('/conversations', [\App\Http\Controllers\Api\ArtisanConversationController::class, 'index']);
    Route::get('/service-requests/{serviceRequest}/conversation', [ConversationController::class, 'show']);
    Route::get('/conversations/{conversation}/messages', [ConversationController::class, 'messages']);
    Route::post('/conversations/{conversation}/messages', [ConversationController::class, 'store']);
    Route::get('/conversations/{conversation}/messages/{message}/attachments/{attachmentId}', [ConversationController::class, 'download']);
    Route::get('/disputes', [DisputeController::class, 'artisanIndex']);
    Route::post('/service-requests/{serviceRequest}/disputes', [DisputeController::class, 'open']);
    Route::post('/disputes/{dispute}/evidence', [DisputeController::class, 'addEvidence']);
});

Route::middleware(['auth:sanctum', 'account.active'])->prefix('email')->group(function () {
    Route::get('/verify', function (Request $request) {
        return $request->user()->hasVerifiedEmail()
            ? response()->json(['success' => true, 'data' => ['verified' => true]])
            : response()->json([
                'success' => false,
                'error' => [
                    'code' => 'EMAIL_NOT_VERIFIED',
                    'message' => 'Please verify your email address.',
                ],
            ], 403);
    })->name('verification.notice');

    Route::get('/verify/{id}/{hash}', function (EmailVerificationRequest $request) {
        if ($request->user()->hasVerifiedEmail()) {
            return response()->json(['success' => true, 'data' => ['verified' => true, 'already' => true]]);
        }

        if ($request->user()->markEmailAsVerified()) {
            event(new Verified($request->user()));
        }

        return response()->json(['success' => true, 'data' => ['verified' => true]]);
    })->middleware(['signed', 'throttle:6,1'])->name('verification.verify');

    Route::post('/verification-notification', function (Request $request) {
        if ($request->user()->hasVerifiedEmail()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'EMAIL_ALREADY_VERIFIED',
                    'message' => 'Email is already verified.',
                ],
            ], 409);
        }

        $request->user()->sendEmailVerificationNotification();

        return response()->json([
            'success' => true,
            'data' => ['message' => 'Verification link sent.'],
        ]);
    })->middleware('throttle:6,1')->name('verification.send');
});

Route::prefix('auth')->middleware('throttle:auth')->group(function () {
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/reset-password', [AuthController::class, 'resetPassword']);
    Route::post('/register/customer', [
        AuthController::class,
        'registerCustomer',
    ]);

    Route::post('/login', [
        AuthController::class,
        'login',
    ]);

    Route::middleware(['auth:sanctum', 'account.active'])->group(function () {
        Route::put('/password', [AuthController::class, 'changePassword']);
        Route::post('/logout', [
            AuthController::class,
            'logout',
        ]);

        Route::get('/me', [
            AuthController::class,
            'me',
        ]);
    });

    Route::post('/register/artisan', [
        AuthController::class,
        'registerArtisan',
    ]);
});

Route::prefix('admin')
    ->middleware(['auth:sanctum', 'account.active'])
    ->group(function () {

        Route::get('/artisans/pending', [
            ArtisanVerificationController::class,
            'pending',
        ])->middleware('permission:view-artisan-applications');
        
        Route::get('/artisans/{artisan}/documents/{slot}', [
            ArtisanVerificationController::class,
            'downloadDocument',
        ])->middleware('permission:view-artisan-applications');

        Route::post('/artisans/{artisan}/approve', [
            ArtisanVerificationController::class,
            'approve',
        ])->middleware(['permission:approve-artisan', 'throttle:verification']);

        Route::post('/artisans/{artisan}/reject', [
            ArtisanVerificationController::class,
            'reject',
        ])->middleware(['permission:reject-artisan', 'throttle:verification']);

        Route::get('/users', [UserManagementController::class, 'index'])
            ->middleware('permission:manage-users');
        Route::patch('/users/{user}/status', [UserManagementController::class, 'updateStatus'])
            ->middleware('permission:manage-users');
        Route::get('/service-requests', [ReportingController::class, 'serviceRequests'])
            ->middleware('permission:manage-services');

        Route::get('/dashboard', [ReportingController::class, 'dashboard'])
            ->middleware('permission:manage-reports');
        Route::get('/payments', [ReportingController::class, 'payments'])
            ->middleware('permission:manage-reports');
        Route::get('/payouts', [ReportingController::class, 'payouts'])
            ->middleware('permission:manage-reports');
        Route::get('/audit-logs', [ReportingController::class, 'auditLogs'])
            ->middleware('permission:manage-reports');

        Route::apiResource('service-categories', ServiceCategoryController::class)
            ->except(['show'])
            ->middleware('permission:manage-services');

        Route::apiResource('services', ServiceController::class)
            ->except(['show'])
            ->middleware('permission:manage-services');

        Route::get('/disputes', [App\Http\Controllers\Api\Admin\DisputeController::class, 'index'])
            ->middleware('permission:manage-disputes');
        Route::get('/disputes/{dispute}', [App\Http\Controllers\Api\Admin\DisputeController::class, 'show'])
            ->middleware('permission:manage-disputes');
        Route::get('/disputes/{dispute}/evidence/{evidenceId}', [
            \App\Http\Controllers\Api\Admin\DisputeController::class,
            'downloadEvidence',
        ])->middleware('permission:manage-disputes');
        Route::post('/disputes/{dispute}/review', [App\Http\Controllers\Api\Admin\DisputeController::class, 'startReview'])
            ->middleware('permission:manage-disputes');
        Route::post('/disputes/{dispute}/awaiting-information', [App\Http\Controllers\Api\Admin\DisputeController::class, 'awaitInformation'])
            ->middleware('permission:manage-disputes');
        Route::post('/disputes/{dispute}/investigate', [App\Http\Controllers\Api\Admin\DisputeController::class, 'investigate'])
            ->middleware('permission:manage-disputes');
        Route::post('/disputes/{dispute}/resolve', [App\Http\Controllers\Api\Admin\DisputeController::class, 'resolve'])
            ->middleware('permission:manage-disputes');
        Route::post('/disputes/{dispute}/confirm-resolution', [App\Http\Controllers\Api\Admin\DisputeController::class, 'confirmResolution'])
            ->middleware('permission:manage-disputes');
        Route::post('/disputes/{dispute}/cancel-resolution', [App\Http\Controllers\Api\Admin\DisputeController::class, 'cancelResolution'])
            ->middleware('permission:manage-disputes');
        Route::post('/disputes/{dispute}/reconcile', [App\Http\Controllers\Api\Admin\DisputeController::class, 'reconcile'])
            ->middleware('permission:manage-disputes');

        Route::get('/settings/commission', [PlatformSettingsController::class, 'commission'])
            ->middleware('permission:manage-platform-settings');
        Route::put('/settings/commission', [PlatformSettingsController::class, 'updateCommission'])
            ->middleware('permission:manage-platform-settings');
    });

Route::middleware(['auth:sanctum', 'account.active'])->group(function () {
    Route::get('/users/{user}/photo', [\App\Http\Controllers\Api\UserController::class, 'photo']);
});
