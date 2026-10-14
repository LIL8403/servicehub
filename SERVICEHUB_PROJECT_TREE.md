├── .codex
├── .github
│   └── modernize
│       └── java-upgrade
│           ├── hooks
│           │   └── scripts
│           │       ├── recordToolUse.ps1
│           │       └── recordToolUse.sh
│           └── .gitignore
├── assets
│   └── logo
│       ├── package.json
│       ├── package-lock.json
│       ├── pjs.ttf
│       ├── PJS-Bold.ttf
│       ├── PlusJakartaSans-ExtraBold.ttf
│       └── PlusJakartaSans-SemiBold.ttf
├── servicehub
│   ├── app
│   │   ├── Ai
│   │   │   └── Agents
│   │   │       ├── AnomalyDetector.php
│   │   │       ├── ArtisanRecommender.php
│   │   │       ├── QuotationAnalyzer.php
│   │   │       └── RequestUnderstandingAgent.php
│   │   ├── Console
│   │   │   └── Commands
│   │   │       ├── ExpireArtisanResponses.php
│   │   │       └── ExpirePendingDisputeResolutions.php
│   │   ├── Contracts
│   │   │   └── Payments
│   │   │       └── CamPayGateway.php
│   │   ├── Enums
│   │   │   ├── AccountStatus.php
│   │   │   ├── DisputeStatus.php
│   │   │   ├── PaymentStatus.php
│   │   │   ├── PayoutStatus.php
│   │   │   ├── ServiceRequestStatus.php
│   │   │   ├── UrgencyLevel.php
│   │   │   └── VerificationStatus.php
│   │   ├── Exceptions
│   │   │   └── RefundNotSupportedException.php
│   │   ├── Http
│   │   │   ├── Controllers
│   │   │   │   ├── Api
│   │   │   │   │   ├── Admin
│   │   │   │   │   │   ├── ArtisanVerificationController.php
│   │   │   │   │   │   ├── DisputeController.php
│   │   │   │   │   │   ├── PlatformSettingsController.php
│   │   │   │   │   │   ├── ReportingController.php
│   │   │   │   │   │   ├── ServiceCategoryController.php
│   │   │   │   │   │   ├── ServiceController.php
│   │   │   │   │   │   └── UserManagementController.php
│   │   │   │   │   ├── Auth
│   │   │   │   │   │   └── AuthController.php
│   │   │   │   │   ├── AiController.php
│   │   │   │   │   ├── ArtisanDiscoveryController.php
│   │   │   │   │   ├── ArtisanRequestController.php
│   │   │   │   │   ├── ArtisanServiceOfferingController.php
│   │   │   │   │   ├── CamPayWebhookController.php
│   │   │   │   │   ├── CatalogController.php
│   │   │   │   │   ├── ConversationController.php
│   │   │   │   │   ├── CustomerConversationController.php
│   │   │   │   │   ├── CustomerPaymentController.php
│   │   │   │   │   ├── DisputeController.php
│   │   │   │   │   ├── DisputeEvidenceController.php
│   │   │   │   │   ├── NotificationController.php
│   │   │   │   │   ├── PaymentController.php
│   │   │   │   │   ├── ProfileController.php
│   │   │   │   │   ├── ReviewController.php
│   │   │   │   │   ├── ServiceRequestController.php
│   │   │   │   │   ├── UserController.php
│   │   │   │   │   └── UserRoleController.php
│   │   │   │   └── Controller.php
│   │   │   ├── Middleware
│   │   │   │   ├── EnsureActiveAccount.php
│   │   │   │   ├── RequirePermission.php
│   │   │   │   └── RequireRole.php
│   │   │   └── Requests
│   │   │       ├── Admin
│   │   │       │   ├── CancelDisputeResolutionRequest.php
│   │   │       │   ├── RejectArtisanRequest.php
│   │   │       │   ├── ResolveDisputeRequest.php
│   │   │       │   ├── StoreServiceCategoryRequest.php
│   │   │       │   ├── StoreServiceRequest.php
│   │   │       │   ├── UpdateAccountStatusRequest.php
│   │   │       │   ├── UpdateCommissionRateRequest.php
│   │   │       │   ├── UpdateDisputeRequest.php
│   │   │       │   ├── UpdateServiceCategoryRequest.php
│   │   │       │   └── UpdateServiceRequest.php
│   │   │       ├── Artisan
│   │   │       │   ├── DeclineRequestRequest.php
│   │   │       │   ├── StoreServiceOfferingRequest.php
│   │   │       │   └── UpdateServiceOfferingRequest.php
│   │   │       ├── Auth
│   │   │       │   ├── ArtisanRegistrationRequest.php
│   │   │       │   ├── ChangePasswordRequest.php
│   │   │       │   ├── CustomerRegistrationRequest.php
│   │   │       │   ├── ForgotPasswordRequest.php
│   │   │       │   ├── LoginRequest.php
│   │   │       │   └── ResetPasswordRequest.php
│   │   │       ├── Conversation
│   │   │       │   └── StoreMessageRequest.php
│   │   │       ├── Dispute
│   │   │       │   ├── AddDisputeEvidenceRequest.php
│   │   │       │   └── OpenDisputeRequest.php
│   │   │       ├── Payment
│   │   │       │   └── InitiatePaymentRequest.php
│   │   │       ├── Profile
│   │   │       │   ├── StoreProfilePhotoRequest.php
│   │   │       │   ├── UpdateArtisanProfileRequest.php
│   │   │       │   └── UpdateCustomerProfileRequest.php
│   │   │       ├── Review
│   │   │       │   └── StoreReviewRequest.php
│   │   │       ├── ServiceRequest
│   │   │       │   ├── ApproveMaterialsRequest.php
│   │   │       │   ├── CancelServiceRequestRequest.php
│   │   │       │   ├── ChangeArtisanRequest.php
│   │   │       │   ├── CompleteInspectionRequest.php
│   │   │       │   ├── ProposeMaterialsRequest.php
│   │   │       │   ├── RejectQuotationRequest.php
│   │   │       │   ├── ReportCompletionRequest.php
│   │   │       │   ├── ScheduleInspectionRequest.php
│   │   │       │   ├── SelectArtisanRequest.php
│   │   │       │   ├── StoreQuotationRequest.php
│   │   │       │   ├── StoreServiceRequestRequest.php
│   │   │       │   └── UpdateServiceRequestRequest.php
│   │   │       └── User
│   │   │           ├── BecomeArtisanRequest.php
│   │   │           └── SwitchRoleRequest.php
│   │   ├── Jobs
│   │   │   ├── AnalyzeQuotationJob.php
│   │   │   └── DetectPaymentAnomalyJob.php
│   │   ├── Models
│   │   │   ├── Administrator.php
│   │   │   ├── Artisan.php
│   │   │   ├── ArtisanProfile.php
│   │   │   ├── AuditLog.php
│   │   │   ├── Conversation.php
│   │   │   ├── Customer.php
│   │   │   ├── Dispute.php
│   │   │   ├── Message.php
│   │   │   ├── Payment.php
│   │   │   ├── Payout.php
│   │   │   ├── PersonalAccessToken.php
│   │   │   ├── PlatformNotification.php
│   │   │   ├── PlatformSetting.php
│   │   │   ├── ResolutionReference.php
│   │   │   ├── Review.php
│   │   │   ├── Service.php
│   │   │   ├── ServiceCategory.php
│   │   │   ├── ServiceRequest.php
│   │   │   └── User.php
│   │   ├── Notifications
│   │   │   └── VerifyEmailNotification.php
│   │   ├── Providers
│   │   │   └── AppServiceProvider.php
│   │   └── Services
│   │       ├── Ai
│   │       │   ├── AiOrchestrationService.php
│   │       │   └── ArtisanRankingService.php
│   │       ├── Artisan
│   │       │   └── ArtisanMatchingService.php
│   │       ├── Location
│   │       │   └── GeocodingService.php
│   │       ├── Payments
│   │       │   ├── CamPayHttpGateway.php
│   │       │   └── SimulatedCamPayGateway.php
│   │       ├── Platform
│   │       │   └── PlatformSettingsService.php
│   │       ├── ServiceRequest
│   │       │   ├── ServiceRequestLifecycleService.php
│   │       │   └── ServiceRequestTrackingService.php
│   │       ├── AdminReportingService.php
│   │       ├── AdminUserManagementService.php
│   │       ├── ArtisanVerificationService.php
│   │       ├── AuditLogService.php
│   │       ├── AuthService.php
│   │       ├── CatalogService.php
│   │       ├── ConversationService.php
│   │       ├── DisputeResolutionService.php
│   │       ├── DisputeService.php
│   │       ├── PaymentService.php
│   │       ├── PlatformNotificationService.php
│   │       ├── ProfilePhotoService.php
│   │       ├── ReviewService.php
│   │       ├── ServiceRequestMediaService.php
│   │       ├── ServiceRequestService.php
│   │       └── UserRoleService.php
│   ├── backups
│   │   └── servicehub
│   │       ├── administrators.bson
│   │       ├── administrators.metadata.json
│   │       ├── artisan_profiles.bson
│   │       ├── artisan_profiles.metadata.json
│   │       ├── artisan_service.bson
│   │       ├── artisan_service.metadata.json
│   │       ├── artisans.bson
│   │       ├── artisans.metadata.json
│   │       ├── audit_logs.bson
│   │       ├── audit_logs.metadata.json
│   │       ├── cache.bson
│   │       ├── cache.metadata.json
│   │       ├── cache_locks.bson
│   │       ├── cache_locks.metadata.json
│   │       ├── conversations.bson
│   │       ├── conversations.metadata.json
│   │       ├── customers.bson
│   │       ├── customers.metadata.json
│   │       ├── disputes.bson
│   │       ├── disputes.metadata.json
│   │       ├── failed_jobs.bson
│   │       ├── failed_jobs.metadata.json
│   │       ├── job_batches.bson
│   │       ├── job_batches.metadata.json
│   │       ├── jobs.bson
│   │       ├── jobs.metadata.json
│   │       ├── messages.bson
│   │       ├── messages.metadata.json
│   │       ├── migrations.bson
│   │       ├── migrations.metadata.json
│   │       ├── model_has_permissions.bson
│   │       ├── model_has_permissions.metadata.json
│   │       ├── model_has_roles.bson
│   │       ├── model_has_roles.metadata.json
│   │       ├── password_reset_tokens.bson
│   │       ├── password_reset_tokens.metadata.json
│   │       ├── payments.bson
│   │       ├── payments.metadata.json
│   │       ├── payouts.bson
│   │       ├── payouts.metadata.json
│   │       ├── permissions.bson
│   │       ├── permissions.metadata.json
│   │       ├── personal_access_tokens.bson
│   │       ├── personal_access_tokens.metadata.json
│   │       ├── platform_notifications.bson
│   │       ├── platform_notifications.metadata.json
│   │       ├── platform_settings.bson
│   │       ├── platform_settings.metadata.json
│   │       ├── prelude.json
│   │       ├── resolution_references.bson
│   │       ├── resolution_references.metadata.json
│   │       ├── reviews.bson
│   │       ├── reviews.metadata.json
│   │       ├── role_has_permissions.bson
│   │       ├── role_has_permissions.metadata.json
│   │       ├── roles.bson
│   │       ├── roles.metadata.json
│   │       ├── service_categories.bson
│   │       ├── service_categories.metadata.json
│   │       ├── service_requests.bson
│   │       ├── service_requests.metadata.json
│   │       ├── services.bson
│   │       ├── services.metadata.json
│   │       ├── sessions.bson
│   │       ├── sessions.metadata.json
│   │       ├── users.bson
│   │       └── users.metadata.json
│   ├── bootstrap
│   │   ├── cache
│   │   │   ├── .gitignore
│   │   │   ├── packages.php
│   │   │   └── services.php
│   │   ├── app.php
│   │   └── providers.php
│   ├── config
│   │   ├── ai.php
│   │   ├── api.php
│   │   ├── app.php
│   │   ├── auth.php
│   │   ├── cache.php
│   │   ├── database.php
│   │   ├── filesystems.php
│   │   ├── logging.php
│   │   ├── mail.php
│   │   ├── queue.php
│   │   ├── roles.php
│   │   ├── sanctum.php
│   │   ├── security.php
│   │   ├── services.php
│   │   ├── session.php
│   │   └── verification.php
│   ├── database
│   │   ├── factories
│   │   │   ├── ServiceRequestFactory.php
│   │   │   └── UserFactory.php
│   │   ├── migrations
│   │   │   ├── 0001_01_01_000000_create_users_table.php
│   │   │   ├── 0001_01_01_000001_create_cache_table.php
│   │   │   ├── 0001_01_01_000002_create_jobs_table.php
│   │   │   ├── 2026_08_11_112502_create_personal_access_tokens_table.php
│   │   │   ├── 2026_08_11_133958_create_artisan_profiles_table.php
│   │   │   ├── 2026_08_11_135232_create_service_categories_table.php
│   │   │   ├── 2026_08_11_135257_create_services_table.php
│   │   │   ├── 2026_09_09_000000_add_core_marketplace_indexes.php
│   │   │   ├── 2026_09_09_000001_align_artisan_verification_statuses.php
│   │   │   ├── 2026_09_09_000002_add_artisan_discovery_indexes.php
│   │   │   ├── 2026_09_09_000003_correct_artisan_offering_index_field.php
│   │   │   ├── 2026_09_09_000004_convert_embedded_json_to_bson_documents.php
│   │   │   ├── 2026_09_09_000005_create_service_requests_collection.php
│   │   │   ├── 2026_09_09_000006_reconcile_mongodb_indexes.php
│   │   │   ├── 2026_09_10_000000_create_payments_collection.php
│   │   │   ├── 2026_09_10_000001_add_artisan_payout_phone_index.php
│   │   │   ├── 2026_09_10_000002_create_payouts_collection.php
│   │   │   ├── 2026_09_10_000003_add_service_request_payment_index.php
│   │   │   ├── 2026_09_12_000000_create_reviews_collection.php
│   │   │   ├── 2026_09_12_000001_create_disputes_collection.php
│   │   │   ├── 2026_09_12_000002_create_conversations_collection.php
│   │   │   ├── 2026_09_12_000003_create_messages_collection.php
│   │   │   ├── 2026_09_12_000004_create_platform_settings_collection.php
│   │   │   ├── 2026_09_12_000005_create_audit_logs_collection.php
│   │   │   ├── 2026_09_12_000006_create_platform_notifications_collection.php
│   │   │   ├── 2026_09_12_000007_create_resolution_references_collection.php
│   │   │   ├── 2026_09_12_000008_add_dispute_resolution_indexes.php
│   │   │   ├── 2026_09_14_000000_convert_json_array_casts_to_bson_arrays.php
│   │   │   ├── 2026_09_23_000000_create_separate_user_role_collections.php
│   │   │   └── 2026_09_29_000000_add_service_request_selection_lifecycle_indexes.php
│   │   ├── seeders
│   │   │   ├── ArtisanSeeder.php
│   │   │   ├── DatabaseSeeder.php
│   │   │   ├── DevelopmentUserSeeder.php
│   │   │   ├── PlatformSettingsSeeder.php
│   │   │   └── ServiceCatalogSeeder.php
│   │   ├── .gitignore
│   │   └── database.sqlite
│   ├── public
│   │   ├── .htaccess
│   │   ├── favicon.ico
│   │   ├── index.php
│   │   └── robots.txt
│   ├── resources
│   │   ├── css
│   │   │   └── app.css
│   │   ├── js
│   │   │   └── app.js
│   │   └── views
│   │       └── welcome.blade.php
│   ├── routes
│   │   ├── api.php
│   │   ├── console.php
│   │   └── web.php
│   ├── storage
│   │   ├── app
│   │   │   ├── private
│   │   │   │   ├── conversations
│   │   │   │   │   └── 6abe2756e82dbe4cc90f4974
│   │   │   │   │       ├── aNlaJCE6YJVF80JMJZeVsicnuY5JCVyV4hAda5pU.png
│   │   │   │   │       └── cceZyXtNsBSc2YctOrMUkGSOIX7P4SpNHxqQxAsW.png
│   │   │   │   ├── disputes
│   │   │   │   │   └── evidence
│   │   │   │   │       ├── 2xtsb22b1V71oY9pjopYyj5qpd8jwIQGg2U2bTtz.png
│   │   │   │   │       ├── c7SvVbrDoDosdjR3vTLlv7jmpwubcfHSHnml2YSK.png
│   │   │   │   │       ├── hK6PgpZPxUltt4HM5bEDUJx9tZY5eKcA1yUnkT9s.png
│   │   │   │   │       ├── JQuNF3P8oJJTl7PwpAopYIEkIaDP0FuY0AYkmct8.png
│   │   │   │   │       ├── JzYXAUhpudmrIfMhajhOP17RrQSU1m8bmRsoFmEG.jpg
│   │   │   │   │       └── SaC20lbzKBBT9xRzqqKJaAEq8gY5JqWsL3vR6sIs.png
│   │   │   │   ├── profile-photos
│   │   │   │   │   ├── 6abc2726ed68ec278604d012
│   │   │   │   │   │   └── avatar.jpg
│   │   │   │   │   ├── 6abc2726ed68ec278604d014
│   │   │   │   │   │   └── avatar.jpg
│   │   │   │   │   ├── 6abc2727ed68ec278604d016
│   │   │   │   │   │   └── avatar.jpg
│   │   │   │   │   ├── 6abc2727ed68ec278604d018
│   │   │   │   │   │   └── avatar.jpg
│   │   │   │   │   ├── 6abc2728ed68ec278604d01a
│   │   │   │   │   │   └── avatar.jpg
│   │   │   │   │   ├── 6abc2728ed68ec278604d01c
│   │   │   │   │   │   └── avatar.jpg
│   │   │   │   │   └── 6abc2729ed68ec278604d01e
│   │   │   │   │       └── avatar.jpg
│   │   │   │   ├── verification
│   │   │   │   │   ├── 6abc2d928dca4851610ebde2
│   │   │   │   │   │   ├── identity-back-37af0ee9-390d-4e73-a02d-0a17cb09ad6a.jpg
│   │   │   │   │   │   ├── identity-front-43468495-c520-47e3-9a08-6a53f1e7fc31.jpg
│   │   │   │   │   │   └── selfie-9e79125a-21e0-456a-8887-31d5e6c382fb.jpg
│   │   │   │   │   └── 6ac01d21af07a02aed084c22
│   │   │   │   │       ├── identity-back-6af8fa4f-7a81-4292-982d-983a0aef8de2.jpg
│   │   │   │   │       ├── identity-front-14515106-ca10-491f-ace8-b20847373dbd.jpg
│   │   │   │   │       ├── selfie-a0dc9ed5-769e-4087-bf69-25155f8eae29.jpg
│   │   │   │   │       ├── supporting-452e9533-fa7f-44e1-af12-5b099294efb4.png
│   │   │   │   │       └── supporting-63733274-c032-4c98-8296-61b1c28911e0.png
│   │   │   │   └── .gitignore
│   │   │   ├── public
│   │   │   │   └── .gitignore
│   │   │   ├── seed
│   │   │   │   └── artisans
│   │   │   │       ├── aline.jpg
│   │   │   │       ├── bernard.jpg
│   │   │   │       ├── claudine.jpg
│   │   │   │       ├── eric.jpg
│   │   │   │       ├── jean.jpg
│   │   │   │       ├── pauline.jpg
│   │   │   │       └── samuel.jpg
│   │   │   └── .gitignore
│   │   ├── framework
│   │   │   ├── cache
│   │   │   │   ├── data
│   │   │   │   │   ├── 0f
│   │   │   │   │   │   ├── ec
│   │   │   │   │   │   │   └── 0fec1643f8c733d479ef7b181276f76259ec1e92
│   │   │   │   │   │   └── fc
│   │   │   │   │   │       └── 0ffcfd8a78eac3e26b74c0eee43c293980b12492
│   │   │   │   │   ├── 10
│   │   │   │   │   │   └── f9
│   │   │   │   │   │       └── 10f973b73141fde3d9ef18dbce18c993d4b22feb
│   │   │   │   │   ├── 15
│   │   │   │   │   │   └── 48
│   │   │   │   │   │       └── 1548bc9ebc408c4f81c9ef4623d9a843ad972f27
│   │   │   │   │   ├── 1c
│   │   │   │   │   │   └── 46
│   │   │   │   │   │       └── 1c46a114e23433e02ed61ff7af61473460741a4f
│   │   │   │   │   ├── 25
│   │   │   │   │   │   └── ee
│   │   │   │   │   │       └── 25ee2d5c31da93a6893c2fd78274823d3605d640
│   │   │   │   │   ├── 26
│   │   │   │   │   │   └── d0
│   │   │   │   │   │       └── 26d0ccb2363a0c1f06dd418a094669dd7d917164
│   │   │   │   │   ├── 2a
│   │   │   │   │   │   └── b3
│   │   │   │   │   │       └── 2ab3db24140e38a7cb2a8bce00bc82f4b425192d
│   │   │   │   │   ├── 2c
│   │   │   │   │   │   └── df
│   │   │   │   │   │       └── 2cdff04636a9ae34bc7be3258174fe267270063e
│   │   │   │   │   ├── 47
│   │   │   │   │   │   └── ca
│   │   │   │   │   │       └── 47cacbd4f12753b8d61959fa6fb4fbc9adb49ca6
│   │   │   │   │   ├── 51
│   │   │   │   │   │   └── 10
│   │   │   │   │   │       └── 5110c878ad3abe119cc9b4a326f8981d18a77582
│   │   │   │   │   ├── 6a
│   │   │   │   │   │   └── 3d
│   │   │   │   │   │       └── 6a3dab0cea8cac12dcaf228d1a956e1a02ee7638
│   │   │   │   │   ├── 76
│   │   │   │   │   │   └── 1c
│   │   │   │   │   │       └── 761cb122b4d83b447fbcdf617ca7da62182b384f
│   │   │   │   │   ├── 81
│   │   │   │   │   │   └── 66
│   │   │   │   │   │       └── 8166fbe6218be6603824ff9c85e2df133254bfa3
│   │   │   │   │   ├── 93
│   │   │   │   │   │   └── 71
│   │   │   │   │   │       └── 93715d8205dc6bfdcf00c993776d41a772ce4a4f
│   │   │   │   │   ├── a8
│   │   │   │   │   │   └── 91
│   │   │   │   │   │       └── a891525c3ba5dd47f0cdf34c03d2758a5a6a0fbe
│   │   │   │   │   ├── af
│   │   │   │   │   │   └── 27
│   │   │   │   │   │       └── af27ef6a6f9f960e2d429f598ea88857d9fed6f9
│   │   │   │   │   ├── bb
│   │   │   │   │   │   └── 24
│   │   │   │   │   │       └── bb2452896e3313cd9e0fa8fe5eebf7e8196d0399
│   │   │   │   │   ├── be
│   │   │   │   │   │   └── 46
│   │   │   │   │   │       └── be46adfb5b7ddb88a9ed38bb3dac5fc6825eb627
│   │   │   │   │   ├── c4
│   │   │   │   │   │   └── eb
│   │   │   │   │   │       └── c4ebcdc1f2cda998a5ad3193f0a974cc6167da02
│   │   │   │   │   ├── c5
│   │   │   │   │   │   └── f4
│   │   │   │   │   │       └── c5f4130c205ea3c382858c982736040826d6b4d9
│   │   │   │   │   ├── d0
│   │   │   │   │   │   └── 25
│   │   │   │   │   │       └── d0255e27b1fc9b138e72fe0a6fdd7ab0f52907b6
│   │   │   │   │   ├── d6
│   │   │   │   │   │   └── 79
│   │   │   │   │   │       └── d679c587630015bd284bf288e0ac33825e4bfefb
│   │   │   │   │   ├── d8
│   │   │   │   │   │   └── 7f
│   │   │   │   │   │       └── d87f0b979270a8b197fe88c415516e88105d9a80
│   │   │   │   │   ├── df
│   │   │   │   │   │   └── b9
│   │   │   │   │   │       └── dfb9ba34d31f2f3332ce374e9f7b8f2a557fab06
│   │   │   │   │   ├── e4
│   │   │   │   │   │   └── b2
│   │   │   │   │   │       └── e4b22b70288086f788f36dfe358532d7eda8cebd
│   │   │   │   │   ├── ed
│   │   │   │   │   │   └── e0
│   │   │   │   │   │       └── ede0587dedf778b6c8a27170c592d4bb62b83f30
│   │   │   │   │   ├── f4
│   │   │   │   │   │   └── 6f
│   │   │   │   │   │       └── f46f2e9ebfeb5d7000b031da65fde3f44a3000fe
│   │   │   │   │   ├── f5
│   │   │   │   │   │   └── 49
│   │   │   │   │   │       └── f549aa75e8712573b14feb689c0e4c647b465d57
│   │   │   │   │   └── .gitignore
│   │   │   │   └── .gitignore
│   │   │   ├── sessions
│   │   │   │   ├── .gitignore
│   │   │   │   └── vrhcXsIf0tJP1isXBxfzAxPyWJJhvJXzLHSQtBwK
│   │   │   ├── testing
│   │   │   │   ├── disks
│   │   │   │   │   ├── local
│   │   │   │   │   │   └── service-requests
│   │   │   │   │   │       └── artisan-request
│   │   │   │   │   │           └── pipe.jpg
│   │   │   │   │   ├── local_test_5
│   │   │   │   │   │   └── conversations
│   │   │   │   │   │       └── 6ab40340d1761a2ec707dc8b
│   │   │   │   │   │           └── 6yptRPcponJN8V1uAPWSD1n4jy8TkSGhwxvKzCtx.jpg
│   │   │   │   │   └── local_test_6
│   │   │   │   │       └── profile-photos
│   │   │   │   │           └── 6ab4034010c27017fa08795b
│   │   │   │   │               └── Brqnu2WaS564Al8gKP8coqHDrlpsYuensdTCw5DX.webp
│   │   │   │   └── .gitignore
│   │   │   ├── views
│   │   │   │   └── .gitignore
│   │   │   └── .gitignore
│   │   └── logs
│   │       ├── .gitignore
│   │       └── laravel.log
│   ├── stubs
│   │   ├── agent.stub
│   │   ├── agent-middleware.stub
│   │   ├── structured-agent.stub
│   │   └── tool.stub
│   ├── tests
│   │   ├── Feature
│   │   │   ├── AdminReportingTest.php
│   │   │   ├── AdminUserManagementTest.php
│   │   │   ├── ArtisanDiscoveryTest.php
│   │   │   ├── ArtisanGeospatialDiscoveryTest.php
│   │   │   ├── ArtisanPayoutPhoneTest.php
│   │   │   ├── ArtisanRankingTest.php
│   │   │   ├── AuthenticationTest.php
│   │   │   ├── CamPayHttpGatewayTest.php
│   │   │   ├── CommissionAndDisputeResolutionTest.php
│   │   │   ├── CompletionPayoutTest.php
│   │   │   ├── ConcurrentArtisanSelectionTest.php
│   │   │   ├── ConversationTest.php
│   │   │   ├── CustomerProfilePhotoTest.php
│   │   │   ├── DisputeTest.php
│   │   │   ├── DualRoleUserTest.php
│   │   │   ├── EmailVerificationTest.php
│   │   │   ├── ExampleTest.php
│   │   │   ├── GeocodingServiceTest.php
│   │   │   ├── InspectionAndQuotationTest.php
│   │   │   ├── MaterialsApprovalTest.php
│   │   │   ├── NotificationApiTest.php
│   │   │   ├── PasswordManagementTest.php
│   │   │   ├── PasswordResetSecurityTest.php
│   │   │   ├── PaymentIdempotencyTest.php
│   │   │   ├── PaymentInitiationTest.php
│   │   │   ├── ProfileAndVerificationTest.php
│   │   │   ├── RateLimitingTest.php
│   │   │   ├── ReviewTest.php
│   │   │   ├── RoleAuthorizationTest.php
│   │   │   ├── ServiceCatalogTest.php
│   │   │   ├── ServiceRequestGeocodingTest.php
│   │   │   ├── ServiceRequestImageTest.php
│   │   │   ├── ServiceRequestLifecycleTest.php
│   │   │   └── ServiceRequestTest.php
│   │   ├── Unit
│   │   │   └── ExampleTest.php
│   │   ├── Pest.php
│   │   └── TestCase.php
│   ├── .editorconfig
│   ├── .env
│   ├── .env.example
│   ├── .gitattributes
│   ├── .gitignore
│   ├── .npmrc
│   ├── api_routes.txt
│   ├── artisan
│   ├── composer.json
│   ├── composer.lock
│   ├── package.json
│   ├── package-lock.json
│   ├── phpunit.xml
│   ├── README.md
│   ├── ssl-test.php
│   ├── test.jpg
│   ├── tracking_backend_dump.txt
│   ├── tracking_sample_response.json
│   └── vite.config.js
├── servicehub_frontend
│   ├── android
│   │   ├── .gradle
│   │   │   ├── 9.1.0
│   │   │   │   ├── checksums
│   │   │   │   │   ├── checksums.lock
│   │   │   │   │   ├── md5-checksums.bin
│   │   │   │   │   └── sha1-checksums.bin
│   │   │   │   ├── executionHistory
│   │   │   │   │   ├── executionHistory.bin
│   │   │   │   │   └── executionHistory.lock
│   │   │   │   ├── expanded
│   │   │   │   ├── fileChanges
│   │   │   │   │   └── last-build.bin
│   │   │   │   ├── fileHashes
│   │   │   │   │   ├── fileHashes.bin
│   │   │   │   │   ├── fileHashes.lock
│   │   │   │   │   └── resourceHashesCache.bin
│   │   │   │   ├── vcsMetadata
│   │   │   │   └── gc.properties
│   │   │   ├── buildOutputCleanup
│   │   │   │   ├── buildOutputCleanup.lock
│   │   │   │   ├── cache.properties
│   │   │   │   └── outputFiles.bin
│   │   │   ├── noVersion
│   │   │   │   └── buildLogic.lock
│   │   │   ├── vcs-1
│   │   │   │   └── gc.properties
│   │   │   └── file-system.probe
│   │   ├── .kotlin
│   │   │   └── sessions
│   │   ├── app
│   │   │   ├── src
│   │   │   │   ├── debug
│   │   │   │   │   └── AndroidManifest.xml
│   │   │   │   ├── main
│   │   │   │   │   ├── java
│   │   │   │   │   │   └── io
│   │   │   │   │   │       └── flutter
│   │   │   │   │   │           └── plugins
│   │   │   │   │   │               └── GeneratedPluginRegistrant.java
│   │   │   │   │   ├── kotlin
│   │   │   │   │   │   └── com
│   │   │   │   │   │       └── example
│   │   │   │   │   │           └── servicehub_frontend
│   │   │   │   │   │               └── MainActivity.kt
│   │   │   │   │   ├── res
│   │   │   │   │   │   ├── drawable
│   │   │   │   │   │   │   └── launch_background.xml
│   │   │   │   │   │   ├── drawable-v21
│   │   │   │   │   │   │   └── launch_background.xml
│   │   │   │   │   │   ├── mipmap-hdpi
│   │   │   │   │   │   │   └── ic_launcher.png
│   │   │   │   │   │   ├── mipmap-mdpi
│   │   │   │   │   │   │   └── ic_launcher.png
│   │   │   │   │   │   ├── mipmap-xhdpi
│   │   │   │   │   │   │   └── ic_launcher.png
│   │   │   │   │   │   ├── mipmap-xxhdpi
│   │   │   │   │   │   │   └── ic_launcher.png
│   │   │   │   │   │   ├── mipmap-xxxhdpi
│   │   │   │   │   │   │   └── ic_launcher.png
│   │   │   │   │   │   ├── values
│   │   │   │   │   │   │   └── styles.xml
│   │   │   │   │   │   └── values-night
│   │   │   │   │   │       └── styles.xml
│   │   │   │   │   └── AndroidManifest.xml
│   │   │   │   └── profile
│   │   │   │       └── AndroidManifest.xml
│   │   │   └── build.gradle.kts
│   │   ├── gradle
│   │   │   └── wrapper
│   │   │       ├── gradle-wrapper.jar
│   │   │       └── gradle-wrapper.properties
│   │   ├── .gitignore
│   │   ├── build.gradle.kts
│   │   ├── gradle.properties
│   │   ├── gradlew
│   │   ├── gradlew.bat
│   │   ├── local.properties
│   │   ├── servicehub_frontend_android.iml
│   │   └── settings.gradle.kts
│   ├── assets
│   │   └── brand
│   │       ├── favicon_16.svg
│   │       ├── favicon_32.svg
│   │       ├── logo_dark_bg.svg
│   │       ├── logo_light_bg.svg
│   │       ├── logo_monochrome.svg
│   │       ├── logo_primary.svg
│   │       ├── logo_stacked.svg
│   │       └── logo_symbol.svg
│   ├── lib
│   │   ├── core
│   │   │   ├── api
│   │   │   │   ├── api_exception.dart
│   │   │   │   ├── api_service.dart
│   │   │   │   ├── authenticated_image_client.dart
│   │   │   │   └── token_storage.dart
│   │   │   ├── constants
│   │   │   │   └── api_constants.dart
│   │   │   ├── localization
│   │   │   │   ├── locale_provider.dart
│   │   │   │   └── locale_storage.dart
│   │   │   ├── location
│   │   │   │   ├── location_permission_dialog.dart
│   │   │   │   ├── location_providers.dart
│   │   │   │   └── location_service.dart
│   │   │   ├── routing
│   │   │   │   └── app_routes.dart
│   │   │   ├── theme
│   │   │   │   └── app_theme.dart
│   │   │   └── utils
│   │   ├── features
│   │   │   ├── admin
│   │   │   │   ├── data
│   │   │   │   │   └── repositories
│   │   │   │   │       ├── admin_audit_log_repository.dart
│   │   │   │   │       ├── admin_category_repository.dart
│   │   │   │   │       ├── admin_dashboard_repository.dart
│   │   │   │   │       ├── admin_dispute_repository.dart
│   │   │   │   │       ├── admin_payment_repository.dart
│   │   │   │   │       ├── admin_payout_repository.dart
│   │   │   │   │       ├── admin_platform_settings_repository.dart
│   │   │   │   │       ├── admin_reporting_repository.dart
│   │   │   │   │       ├── admin_service_repository.dart
│   │   │   │   │       ├── admin_service_request_repository.dart
│   │   │   │   │       ├── admin_user_repository.dart
│   │   │   │   │       └── admin_verification_repository.dart
│   │   │   │   ├── domain
│   │   │   │   │   └── models
│   │   │   │   │       ├── admin_artisan_application.dart
│   │   │   │   │       ├── admin_dashboard_metrics.dart
│   │   │   │   │       ├── admin_dispute_summary.dart
│   │   │   │   │       └── admin_user_summary.dart
│   │   │   │   └── presentation
│   │   │   │       ├── pages
│   │   │   │       │   ├── admin_audit_logs_page.dart
│   │   │   │       │   ├── admin_catalog_page.dart
│   │   │   │       │   ├── admin_categories_page.dart
│   │   │   │       │   ├── admin_coming_soon_page.dart
│   │   │   │       │   ├── admin_dashboard_page.dart
│   │   │   │       │   ├── admin_dispute_detail_page.dart
│   │   │   │       │   ├── admin_dispute_queue_page.dart
│   │   │   │       │   ├── admin_disputes_page.dart
│   │   │   │       │   ├── admin_payments_page.dart
│   │   │   │       │   ├── admin_payouts_page.dart
│   │   │   │       │   ├── admin_platform_settings_page.dart
│   │   │   │       │   ├── admin_reports_page.dart
│   │   │   │       │   ├── admin_service_requests_page.dart
│   │   │   │       │   ├── admin_services_page.dart
│   │   │   │       │   ├── admin_shell_page.dart
│   │   │   │       │   ├── admin_users_page.dart
│   │   │   │       │   ├── admin_verification_detail_page.dart
│   │   │   │       │   ├── admin_verification_page.dart
│   │   │   │       │   └── admin_verification_queue_page.dart
│   │   │   │       ├── providers
│   │   │   │       │   ├── admin_audit_log_providers.dart
│   │   │   │       │   ├── admin_category_providers.dart
│   │   │   │       │   ├── admin_dashboard_providers.dart
│   │   │   │       │   ├── admin_dispute_providers.dart
│   │   │   │       │   ├── admin_payment_providers.dart
│   │   │   │       │   ├── admin_payout_providers.dart
│   │   │   │       │   ├── admin_platform_settings_providers.dart
│   │   │   │       │   ├── admin_reporting_providers.dart
│   │   │   │       │   ├── admin_service_providers.dart
│   │   │   │       │   ├── admin_service_request_providers.dart
│   │   │   │       │   ├── admin_user_providers.dart
│   │   │   │       │   └── admin_verification_providers.dart
│   │   │   │       └── widgets
│   │   │   │           ├── audit
│   │   │   │           │   ├── audit_event_summary.dart
│   │   │   │           │   ├── audit_log_detail_dialog.dart
│   │   │   │           │   └── audit_metadata_table.dart
│   │   │   │           ├── catalog
│   │   │   │           │   ├── catalog_action_icon.dart
│   │   │   │           │   ├── catalog_empty_state.dart
│   │   │   │           │   ├── catalog_filter_chip.dart
│   │   │   │           │   ├── catalog_search_field.dart
│   │   │   │           │   ├── catalog_slug_icon.dart
│   │   │   │           │   ├── catalog_status_pill.dart
│   │   │   │           │   ├── modal_field.dart
│   │   │   │           │   ├── modal_shell.dart
│   │   │   │           │   └── modal_toggle_row.dart
│   │   │   │           ├── categories
│   │   │   │           │   ├── category_delete_dialog.dart
│   │   │   │           │   └── category_form_dialog.dart
│   │   │   │           ├── dashboard
│   │   │   │           │   ├── activity_timeline.dart
│   │   │   │           │   ├── metric_card.dart
│   │   │   │           │   ├── revenue_chart.dart
│   │   │   │           │   ├── review_queue_table.dart
│   │   │   │           │   ├── status_donut.dart
│   │   │   │           │   └── welcome_banner.dart
│   │   │   │           ├── disputes
│   │   │   │           │   ├── cancel_resolution_dialog.dart
│   │   │   │           │   ├── confirm_execution_dialog.dart
│   │   │   │           │   ├── confirm_resolution_dialog.dart
│   │   │   │           │   ├── dispute_action_bar.dart
│   │   │   │           │   ├── dispute_detail_header.dart
│   │   │   │           │   ├── dispute_evidence_grid.dart
│   │   │   │           │   ├── dispute_meta_row.dart
│   │   │   │           │   ├── dispute_queue_item.dart
│   │   │   │           │   ├── dispute_section_card.dart
│   │   │   │           │   ├── dispute_status_pill.dart
│   │   │   │           │   ├── dispute_timeline.dart
│   │   │   │           │   ├── evidence_tile.dart
│   │   │   │           │   ├── notes_action_dialog.dart
│   │   │   │           │   ├── notes_dialog.dart
│   │   │   │           │   ├── pending_resolution_card.dart
│   │   │   │           │   ├── reconcile_dialog.dart
│   │   │   │           │   ├── resolution_reference_field.dart
│   │   │   │           │   ├── resolution_summary_card.dart
│   │   │   │           │   ├── resolve_dispute_dialog.dart
│   │   │   │           │   ├── status_pill.dart
│   │   │   │           │   └── urgency_pill.dart
│   │   │   │           ├── layout
│   │   │   │           │   ├── admin_sidebar.dart
│   │   │   │           │   └── admin_top_nav.dart
│   │   │   │           ├── requests
│   │   │   │           │   ├── service_request_detail_dialog.dart
│   │   │   │           │   └── service_request_status_pill.dart
│   │   │   │           ├── services
│   │   │   │           │   ├── category_dropdown.dart
│   │   │   │           │   ├── service_deactivate_dialog.dart
│   │   │   │           │   └── service_form_dialog.dart
│   │   │   │           ├── settings
│   │   │   │           │   ├── commission_form_card.dart
│   │   │   │           │   └── commission_preview_card.dart
│   │   │   │           ├── transactions
│   │   │   │           │   ├── copyable_reference_field.dart
│   │   │   │           │   ├── event_timeline.dart
│   │   │   │           │   ├── payment_detail_dialog.dart
│   │   │   │           │   ├── payout_detail_dialog.dart
│   │   │   │           │   ├── transaction_pagination_bar.dart
│   │   │   │           │   ├── transaction_reference_cell.dart
│   │   │   │           │   └── transaction_status_pill.dart
│   │   │   │           ├── users
│   │   │   │           │   ├── change_status_dialog.dart
│   │   │   │           │   ├── user_role_pill.dart
│   │   │   │           │   ├── user_status_pill.dart
│   │   │   │           │   └── users_pagination_bar.dart
│   │   │   │           └── verification
│   │   │   │               ├── reject_reason_dialog.dart
│   │   │   │               ├── verification_detail_header.dart
│   │   │   │               ├── verification_document_row.dart
│   │   │   │               ├── verification_empty_queue.dart
│   │   │   │               ├── verification_image_tile.dart
│   │   │   │               ├── verification_label_value_row.dart
│   │   │   │               ├── verification_queue_item.dart
│   │   │   │               ├── verification_section_anchor_nav.dart
│   │   │   │               └── verification_section_card.dart
│   │   │   ├── artisan
│   │   │   │   ├── data
│   │   │   │   │   └── repositories
│   │   │   │   │       ├── artisan_profile_repository.dart
│   │   │   │   │       ├── artisan_request_repository.dart
│   │   │   │   │       ├── artisan_service_offering_repository.dart
│   │   │   │   │       └── artisan_verification_repository.dart
│   │   │   │   ├── domain
│   │   │   │   │   └── models
│   │   │   │   │       ├── artisan_request_summary.dart
│   │   │   │   │       ├── verification_document_type.dart
│   │   │   │   │       └── verification_status.dart
│   │   │   │   └── presentation
│   │   │   │       ├── pages
│   │   │   │       │   ├── artisan_completion_report_page.dart
│   │   │   │       │   ├── artisan_earnings_page.dart
│   │   │   │       │   ├── artisan_earnings_tab.dart
│   │   │   │       │   ├── artisan_home_tab.dart
│   │   │   │       │   ├── artisan_id_document_page.dart
│   │   │   │       │   ├── artisan_identity_form_page.dart
│   │   │   │       │   ├── artisan_inspection_complete_page.dart
│   │   │   │       │   ├── artisan_materials_form_page.dart
│   │   │   │       │   ├── artisan_messages_tab.dart
│   │   │   │       │   ├── artisan_professional_review_page.dart
│   │   │   │       │   ├── artisan_profile_edit_page.dart
│   │   │   │       │   ├── artisan_profile_editor_page.dart
│   │   │   │       │   ├── artisan_profile_tab.dart
│   │   │   │       │   ├── artisan_quotation_form_page.dart
│   │   │   │       │   ├── artisan_report_completion_page.dart
│   │   │   │       │   ├── artisan_request_detail_page.dart
│   │   │   │       │   ├── artisan_requests_tab.dart
│   │   │   │       │   ├── artisan_selfie_capture_page.dart
│   │   │   │       │   ├── artisan_service_offerings_page.dart
│   │   │   │       │   ├── artisan_shell_page.dart
│   │   │   │       │   ├── artisan_submission_review_page.dart
│   │   │   │       │   ├── artisan_supporting_documents_page.dart
│   │   │   │       │   └── artisan_verification_page.dart
│   │   │   │       ├── providers
│   │   │   │       │   ├── artisan_earnings_providers.dart
│   │   │   │       │   ├── artisan_profile_providers.dart
│   │   │   │       │   ├── artisan_request_providers.dart
│   │   │   │       │   ├── artisan_service_offering_providers.dart
│   │   │   │       │   └── artisan_verification_providers.dart
│   │   │   │       └── widgets
│   │   │   │           ├── profile
│   │   │   │           │   ├── add_service_sheet.dart
│   │   │   │           │   ├── experience_stepper.dart
│   │   │   │           │   ├── profile_section_card.dart
│   │   │   │           │   └── services_offered_editor.dart
│   │   │   │           ├── verification
│   │   │   │           │   ├── add_document_type_sheet.dart
│   │   │   │           │   ├── rejection_card.dart
│   │   │   │           │   ├── submission_section_card.dart
│   │   │   │           │   ├── supporting_document_card.dart
│   │   │   │           │   ├── verification_day_chips.dart
│   │   │   │           │   ├── verification_info_card.dart
│   │   │   │           │   ├── verification_photo_slot.dart
│   │   │   │           │   ├── verification_review_block.dart
│   │   │   │           │   ├── verification_step_indicator.dart
│   │   │   │           │   └── verification_text_field.dart
│   │   │   │           ├── artisan_earnings_summary.dart
│   │   │   │           ├── artisan_request_card.dart
│   │   │   │           ├── artisan_status_badge.dart
│   │   │   │           ├── decline_request_dialog.dart
│   │   │   │           ├── earnings_summary_card.dart
│   │   │   │           ├── material_row_editor.dart
│   │   │   │           ├── money_text_field.dart
│   │   │   │           └── verification_status_card.dart
│   │   │   ├── auth
│   │   │   │   ├── data
│   │   │   │   │   └── repositories
│   │   │   │   │       ├── auth_exception.dart
│   │   │   │   │       └── auth_repository.dart
│   │   │   │   ├── domain
│   │   │   │   │   └── models
│   │   │   │   │       ├── auth_response.dart
│   │   │   │   │       └── user.dart
│   │   │   │   ├── models
│   │   │   │   └── presentation
│   │   │   │       ├── pages
│   │   │   │       │   ├── login_page.dart
│   │   │   │       │   └── register_page.dart
│   │   │   │       ├── providers
│   │   │   │       │   └── auth_providers.dart
│   │   │   │       ├── view_models
│   │   │   │       │   ├── login_view_model.dart
│   │   │   │       │   └── register_view_model.dart
│   │   │   │       └── widgets
│   │   │   ├── customer
│   │   │   │   ├── data
│   │   │   │   │   └── repositories
│   │   │   │   │       ├── artisan_directory_repository.dart
│   │   │   │   │       ├── artisan_selection_repository.dart
│   │   │   │   │       ├── conversation_repository.dart
│   │   │   │   │       ├── customer_conversations_repository.dart
│   │   │   │   │       ├── customer_payments_repository.dart
│   │   │   │   │       ├── dispute_repository.dart
│   │   │   │   │       ├── payment_repository.dart
│   │   │   │   │       ├── quotation_repository.dart
│   │   │   │   │       ├── review_repository.dart
│   │   │   │   │       ├── service_request_repository.dart
│   │   │   │   │       └── service_request_tracking_repository.dart
│   │   │   │   ├── domain
│   │   │   │   │   ├── enums
│   │   │   │   │   │   ├── service_request_status.dart
│   │   │   │   │   │   └── urgency_level.dart
│   │   │   │   │   └── models
│   │   │   │   │       ├── artisan_directory_entry.dart
│   │   │   │   │       ├── artisan_summary.dart
│   │   │   │   │       ├── conversation.dart
│   │   │   │   │       ├── conversation_summary.dart
│   │   │   │   │       ├── eligible_artisans_response.dart
│   │   │   │   │       ├── message.dart
│   │   │   │   │       ├── payment_record.dart
│   │   │   │   │       ├── service_category.dart
│   │   │   │   │       ├── service_request.dart
│   │   │   │   │       ├── service_request_draft.dart
│   │   │   │   │       └── service_request_tracking.dart
│   │   │   │   └── presentation
│   │   │   │       ├── pages
│   │   │   │       │   ├── artisan_profile_page.dart
│   │   │   │       │   ├── artisan_public_profile_page.dart
│   │   │   │       │   ├── artisan_selection_page.dart
│   │   │   │       │   ├── conversation_page.dart
│   │   │   │       │   ├── create_request_page.dart
│   │   │   │       │   ├── customer_discover_tab.dart
│   │   │   │       │   ├── customer_home_page.dart
│   │   │   │       │   ├── customer_home_tab.dart
│   │   │   │       │   ├── customer_messages_tab.dart
│   │   │   │       │   ├── customer_payment_history_page.dart
│   │   │   │       │   ├── customer_profile_tab.dart
│   │   │   │       │   ├── customer_requests_tab.dart
│   │   │   │       │   ├── customer_shell_page.dart
│   │   │   │       │   ├── leave_review_page.dart
│   │   │   │       │   ├── report_issue_page.dart
│   │   │   │       │   ├── request_sent_page.dart
│   │   │   │       │   ├── request_success_page.dart
│   │   │   │       │   ├── request_tracking_page.dart
│   │   │   │       │   └── service_categories_page.dart
│   │   │   │       ├── providers
│   │   │   │       │   ├── artisan_directory_providers.dart
│   │   │   │       │   ├── artisan_selection_providers.dart
│   │   │   │       │   ├── conversation_providers.dart
│   │   │   │       │   ├── create_request_providers.dart
│   │   │   │       │   ├── customer_conversations_providers.dart
│   │   │   │       │   ├── customer_payments_providers.dart
│   │   │   │       │   ├── dispute_providers.dart
│   │   │   │       │   ├── my_requests_providers.dart
│   │   │   │       │   ├── payment_providers.dart
│   │   │   │       │   ├── quotation_providers.dart
│   │   │   │       │   ├── request_tracking_providers.dart
│   │   │   │       │   ├── review_providers.dart
│   │   │   │       │   ├── service_catalog_providers.dart
│   │   │   │       │   ├── service_request_tracking_providers.dart
│   │   │   │       │   └── submit_request_providers.dart
│   │   │   │       ├── view_models
│   │   │   │       └── widgets
│   │   │   │           ├── tracking
│   │   │   │           │   ├── sections
│   │   │   │           │   │   └── inspection_schedule_section.dart
│   │   │   │           │   ├── artisan_accepted_view.dart
│   │   │   │           │   ├── awaiting_artisan_selection_view.dart
│   │   │   │           │   ├── awaiting_confirmation_view.dart
│   │   │   │           │   ├── booked_view.dart
│   │   │   │           │   ├── cancelled_view.dart
│   │   │   │           │   ├── completed_view.dart
│   │   │   │           │   ├── disputed_view.dart
│   │   │   │           │   ├── in_progress_view.dart
│   │   │   │           │   ├── info_callout_card.dart
│   │   │   │           │   ├── no_artisan_available_view.dart
│   │   │   │           │   ├── payment_pending_view.dart
│   │   │   │           │   ├── pending_artisan_response_view.dart
│   │   │   │           │   ├── quotation_received_view.dart
│   │   │   │           │   ├── request_details_card.dart
│   │   │   │           │   ├── request_glance_card.dart
│   │   │   │           │   ├── status_hero_card.dart
│   │   │   │           │   ├── tracking_actions.dart
│   │   │   │           │   ├── tracking_app_bar.dart
│   │   │   │           │   ├── tracking_status_badge.dart
│   │   │   │           │   └── tracking_timeline.dart
│   │   │   │           ├── wizard
│   │   │   │           │   ├── ai_assist_card.dart
│   │   │   │           │   ├── date_picker_row.dart
│   │   │   │           │   ├── photo_upload_row.dart
│   │   │   │           │   ├── review_card.dart
│   │   │   │           │   ├── step_1_describe.dart
│   │   │   │           │   ├── step_2_location.dart
│   │   │   │           │   ├── step_3_schedule.dart
│   │   │   │           │   ├── step_4_review.dart
│   │   │   │           │   ├── time_window_pickers.dart
│   │   │   │           │   ├── urgency_radio_list.dart
│   │   │   │           │   └── wizard_progress.dart
│   │   │   │           ├── ai_recommended_card.dart
│   │   │   │           ├── artisan_avatar.dart
│   │   │   │           ├── artisan_card.dart
│   │   │   │           ├── artisan_chip.dart
│   │   │   │           ├── become_artisan_modal.dart
│   │   │   │           ├── category_card.dart
│   │   │   │           ├── compact_artisan_row.dart
│   │   │   │           ├── customer_search_bar.dart
│   │   │   │           ├── featured_artisan_card.dart
│   │   │   │           ├── login_prompt_sheet.dart
│   │   │   │           ├── quick_action_tile.dart
│   │   │   │           ├── request_progress_stepper.dart
│   │   │   │           ├── request_status_chip.dart
│   │   │   │           ├── selection_confirmation_sheet.dart
│   │   │   │           └── service_category_grid_card.dart
│   │   │   ├── landing
│   │   │   │   └── presentation
│   │   │   │       ├── pages
│   │   │   │       │   └── landing_page.dart
│   │   │   │       └── widgets
│   │   │   │           ├── language_selector.dart
│   │   │   │           └── trust_block.dart
│   │   │   ├── shared
│   │   │   │   └── artisan_discovery
│   │   │   │       ├── data
│   │   │   │       │   └── artisan_directory_repository.dart
│   │   │   │       ├── domain
│   │   │   │       │   └── artisan_directory_entry.dart
│   │   │   │       └── presentation
│   │   │   │           ├── pages
│   │   │   │           │   └── artisan_directory_page.dart
│   │   │   │           ├── providers
│   │   │   │           │   └── artisan_directory_providers.dart
│   │   │   │           └── widgets
│   │   │   │               └── artisan_directory_card.dart
│   │   │   └── splash
│   │   │       └── presentation
│   │   │           └── pages
│   │   │               └── splash_page.dart
│   │   ├── l10n
│   │   │   ├── app_en.arb
│   │   │   ├── app_fr.arb
│   │   │   ├── app_localizations.dart
│   │   │   ├── app_localizations_en.dart
│   │   │   └── app_localizations_fr.dart
│   │   ├── shared
│   │   │   └── widgets
│   │   ├── ui
│   │   │   └── core
│   │   │       ├── router
│   │   │       │   ├── app_router.dart
│   │   │       │   └── auth_redirect.dart
│   │   │       └── theme
│   │   │           ├── app_colors.dart
│   │   │           ├── app_radii.dart
│   │   │           ├── app_shadows.dart
│   │   │           ├── app_spacing.dart
│   │   │           ├── app_theme.dart
│   │   │           └── app_typography.dart
│   │   └── main.dart
│   ├── test
│   │   └── widget_test.dart
│   ├── web
│   │   ├── icons
│   │   │   ├── Icon-192.png
│   │   │   ├── Icon-512.png
│   │   │   ├── Icon-maskable-192.png
│   │   │   └── Icon-maskable-512.png
│   │   ├── favicon.png
│   │   ├── index.html
│   │   └── manifest.json
│   ├── windows
│   │   ├── flutter
│   │   │   ├── ephemeral
│   │   │   │   └── .plugin_symlinks
│   │   │   │       ├── file_selector_windows
│   │   │   │       │   ├── example
│   │   │   │       │   │   ├── lib
│   │   │   │       │   │   │   ├── get_directory_page.dart
│   │   │   │       │   │   │   ├── get_multiple_directories_page.dart
│   │   │   │       │   │   │   ├── home_page.dart
│   │   │   │       │   │   │   ├── main.dart
│   │   │   │       │   │   │   ├── open_image_page.dart
│   │   │   │       │   │   │   ├── open_multiple_images_page.dart
│   │   │   │       │   │   │   ├── open_text_page.dart
│   │   │   │       │   │   │   └── save_text_page.dart
│   │   │   │       │   │   ├── windows
│   │   │   │       │   │   │   ├── flutter
│   │   │   │       │   │   │   │   └── CMakeLists.txt
│   │   │   │       │   │   │   ├── runner
│   │   │   │       │   │   │   │   ├── resources
│   │   │   │       │   │   │   │   │   └── app_icon.ico
│   │   │   │       │   │   │   │   ├── CMakeLists.txt
│   │   │   │       │   │   │   │   ├── flutter_window.cpp
│   │   │   │       │   │   │   │   ├── flutter_window.h
│   │   │   │       │   │   │   │   ├── main.cpp
│   │   │   │       │   │   │   │   ├── resource.h
│   │   │   │       │   │   │   │   ├── runner.exe.manifest
│   │   │   │       │   │   │   │   ├── Runner.rc
│   │   │   │       │   │   │   │   ├── utils.cpp
│   │   │   │       │   │   │   │   ├── utils.h
│   │   │   │       │   │   │   │   ├── win32_window.cpp
│   │   │   │       │   │   │   │   └── win32_window.h
│   │   │   │       │   │   │   └── CMakeLists.txt
│   │   │   │       │   │   ├── pubspec.yaml
│   │   │   │       │   │   └── README.md
│   │   │   │       │   ├── lib
│   │   │   │       │   │   ├── src
│   │   │   │       │   │   │   └── messages.g.dart
│   │   │   │       │   │   └── file_selector_windows.dart
│   │   │   │       │   ├── pigeons
│   │   │   │       │   │   ├── copyright.txt
│   │   │   │       │   │   └── messages.dart
│   │   │   │       │   ├── test
│   │   │   │       │   │   └── file_selector_windows_test.dart
│   │   │   │       │   ├── windows
│   │   │   │       │   │   ├── include
│   │   │   │       │   │   │   └── file_selector_windows
│   │   │   │       │   │   │       └── file_selector_windows.h
│   │   │   │       │   │   ├── test
│   │   │   │       │   │   │   ├── file_selector_plugin_test.cpp
│   │   │   │       │   │   │   ├── test_file_dialog_controller.cpp
│   │   │   │       │   │   │   ├── test_file_dialog_controller.h
│   │   │   │       │   │   │   ├── test_main.cpp
│   │   │   │       │   │   │   ├── test_utils.cpp
│   │   │   │       │   │   │   └── test_utils.h
│   │   │   │       │   │   ├── CMakeLists.txt
│   │   │   │       │   │   ├── file_dialog_controller.cpp
│   │   │   │       │   │   ├── file_dialog_controller.h
│   │   │   │       │   │   ├── file_selector_plugin.cpp
│   │   │   │       │   │   ├── file_selector_plugin.h
│   │   │   │       │   │   ├── file_selector_windows.cpp
│   │   │   │       │   │   ├── messages.g.cpp
│   │   │   │       │   │   ├── messages.g.h
│   │   │   │       │   │   ├── string_utils.cpp
│   │   │   │       │   │   └── string_utils.h
│   │   │   │       │   ├── AUTHORS
│   │   │   │       │   ├── CHANGELOG.md
│   │   │   │       │   ├── LICENSE
│   │   │   │       │   ├── pubspec.yaml
│   │   │   │       │   └── README.md
│   │   │   │       ├── flutter_secure_storage_windows
│   │   │   │       │   ├── lib
│   │   │   │       │   │   ├── src
│   │   │   │       │   │   │   ├── flutter_secure_storage_windows_ffi.dart
│   │   │   │       │   │   │   └── flutter_secure_storage_windows_stub.dart
│   │   │   │       │   │   └── flutter_secure_storage_windows.dart
│   │   │   │       │   ├── test
│   │   │   │       │   │   └── unit_test.dart
│   │   │   │       │   ├── windows
│   │   │   │       │   │   ├── include
│   │   │   │       │   │   │   └── flutter_secure_storage_windows
│   │   │   │       │   │   │       └── flutter_secure_storage_windows_plugin.h
│   │   │   │       │   │   ├── test
│   │   │   │       │   │   │   ├── CMakeLists.txt
│   │   │   │       │   │   │   └── flutter_secure_storage_windows_plugin_test.cpp
│   │   │   │       │   │   ├── CMakeLists.txt
│   │   │   │       │   │   ├── flutter_secure_storage_windows_plugin.cpp
│   │   │   │       │   │   └── flutter_secure_storage_windows_plugin.h
│   │   │   │       │   ├── analysis_options.yaml
│   │   │   │       │   ├── CHANGELOG.md
│   │   │   │       │   ├── LICENSE
│   │   │   │       │   ├── pubspec.yaml
│   │   │   │       │   └── README.md
│   │   │   │       ├── geolocator_windows
│   │   │   │       │   ├── example
│   │   │   │       │   │   ├── lib
│   │   │   │       │   │   │   └── main.dart
│   │   │   │       │   │   ├── res
│   │   │   │       │   │   │   └── images
│   │   │   │       │   │   │       ├── baseflow_logo_def_light-02.png
│   │   │   │       │   │   │       ├── poweredByBaseflowLogoLight.png
│   │   │   │       │   │   │       ├── poweredByBaseflowLogoLight@2x.png
│   │   │   │       │   │   │       ├── poweredByBaseflowLogoLight@3x.png
│   │   │   │       │   │   │       └── poweredByBaseflowLogoLight_2020-06-23.zip
│   │   │   │       │   │   ├── windows
│   │   │   │       │   │   │   ├── flutter
│   │   │   │       │   │   │   │   ├── CMakeLists.txt
│   │   │   │       │   │   │   │   ├── generated_plugin_registrant.cc
│   │   │   │       │   │   │   │   ├── generated_plugin_registrant.h
│   │   │   │       │   │   │   │   └── generated_plugins.cmake
│   │   │   │       │   │   │   ├── runner
│   │   │   │       │   │   │   │   ├── resources
│   │   │   │       │   │   │   │   │   └── app_icon.ico
│   │   │   │       │   │   │   │   ├── CMakeLists.txt
│   │   │   │       │   │   │   │   ├── flutter_window.cpp
│   │   │   │       │   │   │   │   ├── flutter_window.h
│   │   │   │       │   │   │   │   ├── main.cpp
│   │   │   │       │   │   │   │   ├── resource.h
│   │   │   │       │   │   │   │   ├── runner.exe.manifest
│   │   │   │       │   │   │   │   ├── Runner.rc
│   │   │   │       │   │   │   │   ├── utils.cpp
│   │   │   │       │   │   │   │   ├── utils.h
│   │   │   │       │   │   │   │   ├── win32_window.cpp
│   │   │   │       │   │   │   │   └── win32_window.h
│   │   │   │       │   │   │   └── CMakeLists.txt
│   │   │   │       │   │   ├── pubspec.yaml
│   │   │   │       │   │   └── README.md
│   │   │   │       │   ├── windows
│   │   │   │       │   │   ├── include
│   │   │   │       │   │   │   └── geolocator_windows
│   │   │   │       │   │   │       └── geolocator_windows.h
│   │   │   │       │   │   ├── CMakeLists.txt
│   │   │   │       │   │   ├── geolocator_enums.h
│   │   │   │       │   │   ├── geolocator_plugin.cpp
│   │   │   │       │   │   ├── geolocator_plugin.h
│   │   │   │       │   │   └── geolocator_windows.cpp
│   │   │   │       │   ├── analysis_options.yaml
│   │   │   │       │   ├── AUTHORS
│   │   │   │       │   ├── CHANGELOG.md
│   │   │   │       │   ├── LICENSE
│   │   │   │       │   ├── pubspec.yaml
│   │   │   │       │   └── README.md
│   │   │   │       ├── image_picker_windows
│   │   │   │       │   ├── example
│   │   │   │       │   │   ├── lib
│   │   │   │       │   │   │   └── main.dart
│   │   │   │       │   │   ├── windows
│   │   │   │       │   │   │   ├── flutter
│   │   │   │       │   │   │   │   ├── CMakeLists.txt
│   │   │   │       │   │   │   │   └── generated_plugins.cmake
│   │   │   │       │   │   │   ├── runner
│   │   │   │       │   │   │   │   ├── resources
│   │   │   │       │   │   │   │   │   └── app_icon.ico
│   │   │   │       │   │   │   │   ├── CMakeLists.txt
│   │   │   │       │   │   │   │   ├── flutter_window.cpp
│   │   │   │       │   │   │   │   ├── flutter_window.h
│   │   │   │       │   │   │   │   ├── main.cpp
│   │   │   │       │   │   │   │   ├── resource.h
│   │   │   │       │   │   │   │   ├── runner.exe.manifest
│   │   │   │       │   │   │   │   ├── Runner.rc
│   │   │   │       │   │   │   │   ├── utils.cpp
│   │   │   │       │   │   │   │   ├── utils.h
│   │   │   │       │   │   │   │   ├── win32_window.cpp
│   │   │   │       │   │   │   │   └── win32_window.h
│   │   │   │       │   │   │   └── CMakeLists.txt
│   │   │   │       │   │   ├── pubspec.yaml
│   │   │   │       │   │   └── README.md
│   │   │   │       │   ├── lib
│   │   │   │       │   │   └── image_picker_windows.dart
│   │   │   │       │   ├── test
│   │   │   │       │   │   ├── image_picker_windows_test.dart
│   │   │   │       │   │   └── image_picker_windows_test.mocks.dart
│   │   │   │       │   ├── AUTHORS
│   │   │   │       │   ├── CHANGELOG.md
│   │   │   │       │   ├── LICENSE
│   │   │   │       │   ├── pubspec.yaml
│   │   │   │       │   └── README.md
│   │   │   │       ├── jni
│   │   │   │       │   ├── android
│   │   │   │       │   │   ├── .cxx
│   │   │   │       │   │   │   ├── Debug
│   │   │   │       │   │   │   │   └── m104s5h4
│   │   │   │       │   │   │   │       ├── arm64-v8a
│   │   │   │       │   │   │   │       │   ├── .cmake
│   │   │   │       │   │   │   │       │   │   └── api
│   │   │   │       │   │   │   │       │   │       └── v1
│   │   │   │       │   │   │   │       │   │           ├── query
│   │   │   │       │   │   │   │       │   │           │   └── client-agp
│   │   │   │       │   │   │   │       │   │           │       ├── cache-v2
│   │   │   │       │   │   │   │       │   │           │       ├── cmakeFiles-v1
│   │   │   │       │   │   │   │       │   │           │       └── codemodel-v2
│   │   │   │       │   │   │   │       │   │           └── reply
│   │   │   │       │   │   │   │       │   │               ├── cache-v2-00af958f474627f3479b.json
│   │   │   │       │   │   │   │       │   │               ├── cmakeFiles-v1-5418827fe1cd73778edb.json
│   │   │   │       │   │   │   │       │   │               ├── codemodel-v2-453b02a42dc576084c0c.json
│   │   │   │       │   │   │   │       │   │               ├── directory-.-Debug-d0094a50bb2071803777.json
│   │   │   │       │   │   │   │       │   │               ├── index-2026-09-26T11-08-43-0748.json
│   │   │   │       │   │   │   │       │   │               └── target-jni-Debug-4b494391707fd7d09f0d.json
│   │   │   │       │   │   │   │       │   ├── CMakeFiles
│   │   │   │       │   │   │   │       │   │   ├── 3.22.1-g37088a8-dirty
│   │   │   │       │   │   │   │       │   │   │   ├── CompilerIdC
│   │   │   │       │   │   │   │       │   │   │   │   ├── tmp
│   │   │   │       │   │   │   │       │   │   │   │   ├── CMakeCCompilerId.c
│   │   │   │       │   │   │   │       │   │   │   │   └── CMakeCCompilerId.o
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeCCompiler.cmake
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeDetermineCompilerABI_C.bin
│   │   │   │       │   │   │   │       │   │   │   └── CMakeSystem.cmake
│   │   │   │       │   │   │   │       │   │   ├── CMakeTmp
│   │   │   │       │   │   │   │       │   │   ├── jni.dir
│   │   │   │       │   │   │   │       │   │   │   ├── include
│   │   │   │       │   │   │   │       │   │   │   │   └── dart_api_dl.c.o
│   │   │   │       │   │   │   │       │   │   │   ├── third_party
│   │   │   │       │   │   │   │       │   │   │   │   └── global_jni_env.c.o
│   │   │   │       │   │   │   │       │   │   │   └── dartjni.c.o
│   │   │   │       │   │   │   │       │   │   ├── cmake.check_cache
│   │   │   │       │   │   │   │       │   │   ├── CMakeOutput.log
│   │   │   │       │   │   │   │       │   │   ├── rules.ninja
│   │   │   │       │   │   │   │       │   │   └── TargetDirectories.txt
│   │   │   │       │   │   │   │       │   ├── .ninja_deps
│   │   │   │       │   │   │   │       │   ├── .ninja_log
│   │   │   │       │   │   │   │       │   ├── additional_project_files.txt
│   │   │   │       │   │   │   │       │   ├── android_gradle_build.json
│   │   │   │       │   │   │   │       │   ├── android_gradle_build_mini.json
│   │   │   │       │   │   │   │       │   ├── build.ninja
│   │   │   │       │   │   │   │       │   ├── build_file_index.txt
│   │   │   │       │   │   │   │       │   ├── cmake_install.cmake
│   │   │   │       │   │   │   │       │   ├── CMakeCache.txt
│   │   │   │       │   │   │   │       │   ├── compile_commands.json
│   │   │   │       │   │   │   │       │   ├── compile_commands.json.bin
│   │   │   │       │   │   │   │       │   ├── configure_fingerprint.bin
│   │   │   │       │   │   │   │       │   ├── metadata_generation_command.txt
│   │   │   │       │   │   │   │       │   ├── prefab_config.json
│   │   │   │       │   │   │   │       │   └── symbol_folder_index.txt
│   │   │   │       │   │   │   │       ├── armeabi-v7a
│   │   │   │       │   │   │   │       │   ├── .cmake
│   │   │   │       │   │   │   │       │   │   └── api
│   │   │   │       │   │   │   │       │   │       └── v1
│   │   │   │       │   │   │   │       │   │           ├── query
│   │   │   │       │   │   │   │       │   │           │   └── client-agp
│   │   │   │       │   │   │   │       │   │           │       ├── cache-v2
│   │   │   │       │   │   │   │       │   │           │       ├── cmakeFiles-v1
│   │   │   │       │   │   │   │       │   │           │       └── codemodel-v2
│   │   │   │       │   │   │   │       │   │           └── reply
│   │   │   │       │   │   │   │       │   │               ├── cache-v2-799e574350750b64947d.json
│   │   │   │       │   │   │   │       │   │               ├── cmakeFiles-v1-9f6fb5fefcb492505749.json
│   │   │   │       │   │   │   │       │   │               ├── codemodel-v2-a4865092b5287d0d1599.json
│   │   │   │       │   │   │   │       │   │               ├── directory-.-Debug-d0094a50bb2071803777.json
│   │   │   │       │   │   │   │       │   │               ├── index-2026-09-26T11-08-51-0149.json
│   │   │   │       │   │   │   │       │   │               └── target-jni-Debug-8ec9ac4a5ea828010d0d.json
│   │   │   │       │   │   │   │       │   ├── CMakeFiles
│   │   │   │       │   │   │   │       │   │   ├── 3.22.1-g37088a8-dirty
│   │   │   │       │   │   │   │       │   │   │   ├── CompilerIdC
│   │   │   │       │   │   │   │       │   │   │   │   ├── tmp
│   │   │   │       │   │   │   │       │   │   │   │   ├── CMakeCCompilerId.c
│   │   │   │       │   │   │   │       │   │   │   │   └── CMakeCCompilerId.o
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeCCompiler.cmake
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeDetermineCompilerABI_C.bin
│   │   │   │       │   │   │   │       │   │   │   └── CMakeSystem.cmake
│   │   │   │       │   │   │   │       │   │   ├── CMakeTmp
│   │   │   │       │   │   │   │       │   │   ├── jni.dir
│   │   │   │       │   │   │   │       │   │   │   ├── include
│   │   │   │       │   │   │   │       │   │   │   │   └── dart_api_dl.c.o
│   │   │   │       │   │   │   │       │   │   │   ├── third_party
│   │   │   │       │   │   │   │       │   │   │   │   └── global_jni_env.c.o
│   │   │   │       │   │   │   │       │   │   │   └── dartjni.c.o
│   │   │   │       │   │   │   │       │   │   ├── cmake.check_cache
│   │   │   │       │   │   │   │       │   │   ├── CMakeOutput.log
│   │   │   │       │   │   │   │       │   │   ├── rules.ninja
│   │   │   │       │   │   │   │       │   │   └── TargetDirectories.txt
│   │   │   │       │   │   │   │       │   ├── .ninja_deps
│   │   │   │       │   │   │   │       │   ├── .ninja_log
│   │   │   │       │   │   │   │       │   ├── additional_project_files.txt
│   │   │   │       │   │   │   │       │   ├── android_gradle_build.json
│   │   │   │       │   │   │   │       │   ├── android_gradle_build_mini.json
│   │   │   │       │   │   │   │       │   ├── build.ninja
│   │   │   │       │   │   │   │       │   ├── build_file_index.txt
│   │   │   │       │   │   │   │       │   ├── cmake_install.cmake
│   │   │   │       │   │   │   │       │   ├── CMakeCache.txt
│   │   │   │       │   │   │   │       │   ├── compile_commands.json
│   │   │   │       │   │   │   │       │   ├── compile_commands.json.bin
│   │   │   │       │   │   │   │       │   ├── configure_fingerprint.bin
│   │   │   │       │   │   │   │       │   ├── metadata_generation_command.txt
│   │   │   │       │   │   │   │       │   ├── prefab_config.json
│   │   │   │       │   │   │   │       │   └── symbol_folder_index.txt
│   │   │   │       │   │   │   │       ├── x86
│   │   │   │       │   │   │   │       │   ├── .cmake
│   │   │   │       │   │   │   │       │   │   └── api
│   │   │   │       │   │   │   │       │   │       └── v1
│   │   │   │       │   │   │   │       │   │           ├── query
│   │   │   │       │   │   │   │       │   │           │   └── client-agp
│   │   │   │       │   │   │   │       │   │           │       ├── cache-v2
│   │   │   │       │   │   │   │       │   │           │       ├── cmakeFiles-v1
│   │   │   │       │   │   │   │       │   │           │       └── codemodel-v2
│   │   │   │       │   │   │   │       │   │           └── reply
│   │   │   │       │   │   │   │       │   │               ├── cache-v2-682a6543110f9bd9d8f3.json
│   │   │   │       │   │   │   │       │   │               ├── cmakeFiles-v1-237f34a6459c41ce3d38.json
│   │   │   │       │   │   │   │       │   │               ├── codemodel-v2-0b23b3575778ffa6e215.json
│   │   │   │       │   │   │   │       │   │               ├── directory-.-Debug-d0094a50bb2071803777.json
│   │   │   │       │   │   │   │       │   │               ├── index-2026-09-26T11-08-58-0833.json
│   │   │   │       │   │   │   │       │   │               └── target-jni-Debug-3bd14344aea12660c05a.json
│   │   │   │       │   │   │   │       │   ├── CMakeFiles
│   │   │   │       │   │   │   │       │   │   ├── 3.22.1-g37088a8-dirty
│   │   │   │       │   │   │   │       │   │   │   ├── CompilerIdC
│   │   │   │       │   │   │   │       │   │   │   │   ├── tmp
│   │   │   │       │   │   │   │       │   │   │   │   ├── CMakeCCompilerId.c
│   │   │   │       │   │   │   │       │   │   │   │   └── CMakeCCompilerId.o
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeCCompiler.cmake
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeDetermineCompilerABI_C.bin
│   │   │   │       │   │   │   │       │   │   │   └── CMakeSystem.cmake
│   │   │   │       │   │   │   │       │   │   ├── CMakeTmp
│   │   │   │       │   │   │   │       │   │   ├── jni.dir
│   │   │   │       │   │   │   │       │   │   │   ├── include
│   │   │   │       │   │   │   │       │   │   │   │   └── dart_api_dl.c.o
│   │   │   │       │   │   │   │       │   │   │   ├── third_party
│   │   │   │       │   │   │   │       │   │   │   │   └── global_jni_env.c.o
│   │   │   │       │   │   │   │       │   │   │   └── dartjni.c.o
│   │   │   │       │   │   │   │       │   │   ├── cmake.check_cache
│   │   │   │       │   │   │   │       │   │   ├── CMakeOutput.log
│   │   │   │       │   │   │   │       │   │   ├── rules.ninja
│   │   │   │       │   │   │   │       │   │   └── TargetDirectories.txt
│   │   │   │       │   │   │   │       │   ├── .ninja_deps
│   │   │   │       │   │   │   │       │   ├── .ninja_log
│   │   │   │       │   │   │   │       │   ├── additional_project_files.txt
│   │   │   │       │   │   │   │       │   ├── android_gradle_build.json
│   │   │   │       │   │   │   │       │   ├── android_gradle_build_mini.json
│   │   │   │       │   │   │   │       │   ├── build.ninja
│   │   │   │       │   │   │   │       │   ├── build_file_index.txt
│   │   │   │       │   │   │   │       │   ├── cmake_install.cmake
│   │   │   │       │   │   │   │       │   ├── CMakeCache.txt
│   │   │   │       │   │   │   │       │   ├── compile_commands.json
│   │   │   │       │   │   │   │       │   ├── compile_commands.json.bin
│   │   │   │       │   │   │   │       │   ├── configure_fingerprint.bin
│   │   │   │       │   │   │   │       │   ├── metadata_generation_command.txt
│   │   │   │       │   │   │   │       │   ├── prefab_config.json
│   │   │   │       │   │   │   │       │   └── symbol_folder_index.txt
│   │   │   │       │   │   │   │       ├── x86_64
│   │   │   │       │   │   │   │       │   ├── .cmake
│   │   │   │       │   │   │   │       │   │   └── api
│   │   │   │       │   │   │   │       │   │       └── v1
│   │   │   │       │   │   │   │       │   │           ├── query
│   │   │   │       │   │   │   │       │   │           │   └── client-agp
│   │   │   │       │   │   │   │       │   │           │       ├── cache-v2
│   │   │   │       │   │   │   │       │   │           │       ├── cmakeFiles-v1
│   │   │   │       │   │   │   │       │   │           │       └── codemodel-v2
│   │   │   │       │   │   │   │       │   │           └── reply
│   │   │   │       │   │   │   │       │   │               ├── cache-v2-1b5679b9dffe5ef5d1c1.json
│   │   │   │       │   │   │   │       │   │               ├── cmakeFiles-v1-81b00860ef4c5ed9cd27.json
│   │   │   │       │   │   │   │       │   │               ├── codemodel-v2-5833aac1ed687e874d3a.json
│   │   │   │       │   │   │   │       │   │               ├── directory-.-Debug-d0094a50bb2071803777.json
│   │   │   │       │   │   │   │       │   │               ├── index-2026-09-26T11-09-06-0363.json
│   │   │   │       │   │   │   │       │   │               └── target-jni-Debug-d696afa84723dfefaf04.json
│   │   │   │       │   │   │   │       │   ├── CMakeFiles
│   │   │   │       │   │   │   │       │   │   ├── 3.22.1-g37088a8-dirty
│   │   │   │       │   │   │   │       │   │   │   ├── CompilerIdC
│   │   │   │       │   │   │   │       │   │   │   │   ├── tmp
│   │   │   │       │   │   │   │       │   │   │   │   ├── CMakeCCompilerId.c
│   │   │   │       │   │   │   │       │   │   │   │   └── CMakeCCompilerId.o
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeCCompiler.cmake
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeDetermineCompilerABI_C.bin
│   │   │   │       │   │   │   │       │   │   │   └── CMakeSystem.cmake
│   │   │   │       │   │   │   │       │   │   ├── CMakeTmp
│   │   │   │       │   │   │   │       │   │   ├── jni.dir
│   │   │   │       │   │   │   │       │   │   │   ├── include
│   │   │   │       │   │   │   │       │   │   │   │   └── dart_api_dl.c.o
│   │   │   │       │   │   │   │       │   │   │   ├── third_party
│   │   │   │       │   │   │   │       │   │   │   │   └── global_jni_env.c.o
│   │   │   │       │   │   │   │       │   │   │   └── dartjni.c.o
│   │   │   │       │   │   │   │       │   │   ├── cmake.check_cache
│   │   │   │       │   │   │   │       │   │   ├── CMakeOutput.log
│   │   │   │       │   │   │   │       │   │   ├── rules.ninja
│   │   │   │       │   │   │   │       │   │   └── TargetDirectories.txt
│   │   │   │       │   │   │   │       │   ├── .ninja_deps
│   │   │   │       │   │   │   │       │   ├── .ninja_log
│   │   │   │       │   │   │   │       │   ├── additional_project_files.txt
│   │   │   │       │   │   │   │       │   ├── android_gradle_build.json
│   │   │   │       │   │   │   │       │   ├── android_gradle_build_mini.json
│   │   │   │       │   │   │   │       │   ├── build.ninja
│   │   │   │       │   │   │   │       │   ├── build_file_index.txt
│   │   │   │       │   │   │   │       │   ├── cmake_install.cmake
│   │   │   │       │   │   │   │       │   ├── CMakeCache.txt
│   │   │   │       │   │   │   │       │   ├── compile_commands.json
│   │   │   │       │   │   │   │       │   ├── compile_commands.json.bin
│   │   │   │       │   │   │   │       │   ├── configure_fingerprint.bin
│   │   │   │       │   │   │   │       │   ├── metadata_generation_command.txt
│   │   │   │       │   │   │   │       │   ├── prefab_config.json
│   │   │   │       │   │   │   │       │   └── symbol_folder_index.txt
│   │   │   │       │   │   │   │       └── hash_key.txt
│   │   │   │       │   │   │   ├── RelWithDebInfo
│   │   │   │       │   │   │   │   └── 4hc5p4k1
│   │   │   │       │   │   │   │       ├── arm64-v8a
│   │   │   │       │   │   │   │       │   ├── .cmake
│   │   │   │       │   │   │   │       │   │   └── api
│   │   │   │       │   │   │   │       │   │       └── v1
│   │   │   │       │   │   │   │       │   │           ├── query
│   │   │   │       │   │   │   │       │   │           │   └── client-agp
│   │   │   │       │   │   │   │       │   │           │       ├── cache-v2
│   │   │   │       │   │   │   │       │   │           │       ├── cmakeFiles-v1
│   │   │   │       │   │   │   │       │   │           │       └── codemodel-v2
│   │   │   │       │   │   │   │       │   │           └── reply
│   │   │   │       │   │   │   │       │   │               ├── cache-v2-3a9f84b6ac91c73cd68e.json
│   │   │   │       │   │   │   │       │   │               ├── cmakeFiles-v1-1fcc197118d93fcbf830.json
│   │   │   │       │   │   │   │       │   │               ├── codemodel-v2-2f923c34e7ef63dc026e.json
│   │   │   │       │   │   │   │       │   │               ├── directory-.-RelWithDebInfo-d0094a50bb2071803777.json
│   │   │   │       │   │   │   │       │   │               ├── index-2026-09-30T20-25-10-0671.json
│   │   │   │       │   │   │   │       │   │               └── target-jni-RelWithDebInfo-f1714448ec7939e49f47.json
│   │   │   │       │   │   │   │       │   ├── CMakeFiles
│   │   │   │       │   │   │   │       │   │   ├── 3.22.1-g37088a8-dirty
│   │   │   │       │   │   │   │       │   │   │   ├── CompilerIdC
│   │   │   │       │   │   │   │       │   │   │   │   ├── tmp
│   │   │   │       │   │   │   │       │   │   │   │   ├── CMakeCCompilerId.c
│   │   │   │       │   │   │   │       │   │   │   │   └── CMakeCCompilerId.o
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeCCompiler.cmake
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeDetermineCompilerABI_C.bin
│   │   │   │       │   │   │   │       │   │   │   └── CMakeSystem.cmake
│   │   │   │       │   │   │   │       │   │   ├── CMakeTmp
│   │   │   │       │   │   │   │       │   │   ├── jni.dir
│   │   │   │       │   │   │   │       │   │   │   ├── include
│   │   │   │       │   │   │   │       │   │   │   │   └── dart_api_dl.c.o
│   │   │   │       │   │   │   │       │   │   │   ├── third_party
│   │   │   │       │   │   │   │       │   │   │   │   └── global_jni_env.c.o
│   │   │   │       │   │   │   │       │   │   │   └── dartjni.c.o
│   │   │   │       │   │   │   │       │   │   ├── cmake.check_cache
│   │   │   │       │   │   │   │       │   │   ├── CMakeOutput.log
│   │   │   │       │   │   │   │       │   │   ├── rules.ninja
│   │   │   │       │   │   │   │       │   │   └── TargetDirectories.txt
│   │   │   │       │   │   │   │       │   ├── .ninja_deps
│   │   │   │       │   │   │   │       │   ├── .ninja_log
│   │   │   │       │   │   │   │       │   ├── additional_project_files.txt
│   │   │   │       │   │   │   │       │   ├── android_gradle_build.json
│   │   │   │       │   │   │   │       │   ├── android_gradle_build_mini.json
│   │   │   │       │   │   │   │       │   ├── build.ninja
│   │   │   │       │   │   │   │       │   ├── build_file_index.txt
│   │   │   │       │   │   │   │       │   ├── cmake_install.cmake
│   │   │   │       │   │   │   │       │   ├── CMakeCache.txt
│   │   │   │       │   │   │   │       │   ├── compile_commands.json
│   │   │   │       │   │   │   │       │   ├── compile_commands.json.bin
│   │   │   │       │   │   │   │       │   ├── configure_fingerprint.bin
│   │   │   │       │   │   │   │       │   ├── metadata_generation_command.txt
│   │   │   │       │   │   │   │       │   ├── prefab_config.json
│   │   │   │       │   │   │   │       │   └── symbol_folder_index.txt
│   │   │   │       │   │   │   │       ├── armeabi-v7a
│   │   │   │       │   │   │   │       │   ├── .cmake
│   │   │   │       │   │   │   │       │   │   └── api
│   │   │   │       │   │   │   │       │   │       └── v1
│   │   │   │       │   │   │   │       │   │           ├── query
│   │   │   │       │   │   │   │       │   │           │   └── client-agp
│   │   │   │       │   │   │   │       │   │           │       ├── cache-v2
│   │   │   │       │   │   │   │       │   │           │       ├── cmakeFiles-v1
│   │   │   │       │   │   │   │       │   │           │       └── codemodel-v2
│   │   │   │       │   │   │   │       │   │           └── reply
│   │   │   │       │   │   │   │       │   │               ├── cache-v2-fef37756d43203218b8b.json
│   │   │   │       │   │   │   │       │   │               ├── cmakeFiles-v1-348c8e1653ebb865daf9.json
│   │   │   │       │   │   │   │       │   │               ├── codemodel-v2-6d1f79e2db791c530273.json
│   │   │   │       │   │   │   │       │   │               ├── directory-.-RelWithDebInfo-d0094a50bb2071803777.json
│   │   │   │       │   │   │   │       │   │               ├── index-2026-09-30T20-25-17-0592.json
│   │   │   │       │   │   │   │       │   │               └── target-jni-RelWithDebInfo-2fbec785315660af9965.json
│   │   │   │       │   │   │   │       │   ├── CMakeFiles
│   │   │   │       │   │   │   │       │   │   ├── 3.22.1-g37088a8-dirty
│   │   │   │       │   │   │   │       │   │   │   ├── CompilerIdC
│   │   │   │       │   │   │   │       │   │   │   │   ├── tmp
│   │   │   │       │   │   │   │       │   │   │   │   ├── CMakeCCompilerId.c
│   │   │   │       │   │   │   │       │   │   │   │   └── CMakeCCompilerId.o
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeCCompiler.cmake
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeDetermineCompilerABI_C.bin
│   │   │   │       │   │   │   │       │   │   │   └── CMakeSystem.cmake
│   │   │   │       │   │   │   │       │   │   ├── CMakeTmp
│   │   │   │       │   │   │   │       │   │   ├── jni.dir
│   │   │   │       │   │   │   │       │   │   │   ├── include
│   │   │   │       │   │   │   │       │   │   │   │   └── dart_api_dl.c.o
│   │   │   │       │   │   │   │       │   │   │   ├── third_party
│   │   │   │       │   │   │   │       │   │   │   │   └── global_jni_env.c.o
│   │   │   │       │   │   │   │       │   │   │   └── dartjni.c.o
│   │   │   │       │   │   │   │       │   │   ├── cmake.check_cache
│   │   │   │       │   │   │   │       │   │   ├── CMakeOutput.log
│   │   │   │       │   │   │   │       │   │   ├── rules.ninja
│   │   │   │       │   │   │   │       │   │   └── TargetDirectories.txt
│   │   │   │       │   │   │   │       │   ├── .ninja_deps
│   │   │   │       │   │   │   │       │   ├── .ninja_log
│   │   │   │       │   │   │   │       │   ├── additional_project_files.txt
│   │   │   │       │   │   │   │       │   ├── android_gradle_build.json
│   │   │   │       │   │   │   │       │   ├── android_gradle_build_mini.json
│   │   │   │       │   │   │   │       │   ├── build.ninja
│   │   │   │       │   │   │   │       │   ├── build_file_index.txt
│   │   │   │       │   │   │   │       │   ├── cmake_install.cmake
│   │   │   │       │   │   │   │       │   ├── CMakeCache.txt
│   │   │   │       │   │   │   │       │   ├── compile_commands.json
│   │   │   │       │   │   │   │       │   ├── compile_commands.json.bin
│   │   │   │       │   │   │   │       │   ├── configure_fingerprint.bin
│   │   │   │       │   │   │   │       │   ├── metadata_generation_command.txt
│   │   │   │       │   │   │   │       │   ├── prefab_config.json
│   │   │   │       │   │   │   │       │   └── symbol_folder_index.txt
│   │   │   │       │   │   │   │       ├── x86
│   │   │   │       │   │   │   │       │   ├── .cmake
│   │   │   │       │   │   │   │       │   │   └── api
│   │   │   │       │   │   │   │       │   │       └── v1
│   │   │   │       │   │   │   │       │   │           ├── query
│   │   │   │       │   │   │   │       │   │           │   └── client-agp
│   │   │   │       │   │   │   │       │   │           │       ├── cache-v2
│   │   │   │       │   │   │   │       │   │           │       ├── cmakeFiles-v1
│   │   │   │       │   │   │   │       │   │           │       └── codemodel-v2
│   │   │   │       │   │   │   │       │   │           └── reply
│   │   │   │       │   │   │   │       │   │               ├── cache-v2-b736f68c24d9ef01c612.json
│   │   │   │       │   │   │   │       │   │               ├── cmakeFiles-v1-31ea6d364f89c6965af3.json
│   │   │   │       │   │   │   │       │   │               ├── codemodel-v2-459a3dd11105a2ac9704.json
│   │   │   │       │   │   │   │       │   │               ├── directory-.-RelWithDebInfo-d0094a50bb2071803777.json
│   │   │   │       │   │   │   │       │   │               ├── index-2026-09-30T20-25-24-0935.json
│   │   │   │       │   │   │   │       │   │               └── target-jni-RelWithDebInfo-956f1c06eb9dd0de4d4e.json
│   │   │   │       │   │   │   │       │   ├── CMakeFiles
│   │   │   │       │   │   │   │       │   │   ├── 3.22.1-g37088a8-dirty
│   │   │   │       │   │   │   │       │   │   │   ├── CompilerIdC
│   │   │   │       │   │   │   │       │   │   │   │   ├── tmp
│   │   │   │       │   │   │   │       │   │   │   │   ├── CMakeCCompilerId.c
│   │   │   │       │   │   │   │       │   │   │   │   └── CMakeCCompilerId.o
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeCCompiler.cmake
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeDetermineCompilerABI_C.bin
│   │   │   │       │   │   │   │       │   │   │   └── CMakeSystem.cmake
│   │   │   │       │   │   │   │       │   │   ├── CMakeTmp
│   │   │   │       │   │   │   │       │   │   ├── jni.dir
│   │   │   │       │   │   │   │       │   │   │   ├── include
│   │   │   │       │   │   │   │       │   │   │   │   └── dart_api_dl.c.o
│   │   │   │       │   │   │   │       │   │   │   ├── third_party
│   │   │   │       │   │   │   │       │   │   │   │   └── global_jni_env.c.o
│   │   │   │       │   │   │   │       │   │   │   └── dartjni.c.o
│   │   │   │       │   │   │   │       │   │   ├── cmake.check_cache
│   │   │   │       │   │   │   │       │   │   ├── CMakeOutput.log
│   │   │   │       │   │   │   │       │   │   ├── rules.ninja
│   │   │   │       │   │   │   │       │   │   └── TargetDirectories.txt
│   │   │   │       │   │   │   │       │   ├── .ninja_deps
│   │   │   │       │   │   │   │       │   ├── .ninja_log
│   │   │   │       │   │   │   │       │   ├── additional_project_files.txt
│   │   │   │       │   │   │   │       │   ├── android_gradle_build.json
│   │   │   │       │   │   │   │       │   ├── android_gradle_build_mini.json
│   │   │   │       │   │   │   │       │   ├── build.ninja
│   │   │   │       │   │   │   │       │   ├── build_file_index.txt
│   │   │   │       │   │   │   │       │   ├── cmake_install.cmake
│   │   │   │       │   │   │   │       │   ├── CMakeCache.txt
│   │   │   │       │   │   │   │       │   ├── compile_commands.json
│   │   │   │       │   │   │   │       │   ├── compile_commands.json.bin
│   │   │   │       │   │   │   │       │   ├── configure_fingerprint.bin
│   │   │   │       │   │   │   │       │   ├── metadata_generation_command.txt
│   │   │   │       │   │   │   │       │   ├── prefab_config.json
│   │   │   │       │   │   │   │       │   └── symbol_folder_index.txt
│   │   │   │       │   │   │   │       ├── x86_64
│   │   │   │       │   │   │   │       │   ├── .cmake
│   │   │   │       │   │   │   │       │   │   └── api
│   │   │   │       │   │   │   │       │   │       └── v1
│   │   │   │       │   │   │   │       │   │           ├── query
│   │   │   │       │   │   │   │       │   │           │   └── client-agp
│   │   │   │       │   │   │   │       │   │           │       ├── cache-v2
│   │   │   │       │   │   │   │       │   │           │       ├── cmakeFiles-v1
│   │   │   │       │   │   │   │       │   │           │       └── codemodel-v2
│   │   │   │       │   │   │   │       │   │           └── reply
│   │   │   │       │   │   │   │       │   │               ├── cache-v2-bdf61dea68f5479ba523.json
│   │   │   │       │   │   │   │       │   │               ├── cmakeFiles-v1-3d323d984ba05fd36109.json
│   │   │   │       │   │   │   │       │   │               ├── codemodel-v2-c6fea52c3dd98f6f032d.json
│   │   │   │       │   │   │   │       │   │               ├── directory-.-RelWithDebInfo-d0094a50bb2071803777.json
│   │   │   │       │   │   │   │       │   │               ├── index-2026-09-30T20-25-31-0960.json
│   │   │   │       │   │   │   │       │   │               └── target-jni-RelWithDebInfo-1e256c22fb6eca555d90.json
│   │   │   │       │   │   │   │       │   ├── CMakeFiles
│   │   │   │       │   │   │   │       │   │   ├── 3.22.1-g37088a8-dirty
│   │   │   │       │   │   │   │       │   │   │   ├── CompilerIdC
│   │   │   │       │   │   │   │       │   │   │   │   ├── tmp
│   │   │   │       │   │   │   │       │   │   │   │   ├── CMakeCCompilerId.c
│   │   │   │       │   │   │   │       │   │   │   │   └── CMakeCCompilerId.o
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeCCompiler.cmake
│   │   │   │       │   │   │   │       │   │   │   ├── CMakeDetermineCompilerABI_C.bin
│   │   │   │       │   │   │   │       │   │   │   └── CMakeSystem.cmake
│   │   │   │       │   │   │   │       │   │   ├── CMakeTmp
│   │   │   │       │   │   │   │       │   │   ├── jni.dir
│   │   │   │       │   │   │   │       │   │   │   ├── include
│   │   │   │       │   │   │   │       │   │   │   │   └── dart_api_dl.c.o
│   │   │   │       │   │   │   │       │   │   │   ├── third_party
│   │   │   │       │   │   │   │       │   │   │   │   └── global_jni_env.c.o
│   │   │   │       │   │   │   │       │   │   │   └── dartjni.c.o
│   │   │   │       │   │   │   │       │   │   ├── cmake.check_cache
│   │   │   │       │   │   │   │       │   │   ├── CMakeOutput.log
│   │   │   │       │   │   │   │       │   │   ├── rules.ninja
│   │   │   │       │   │   │   │       │   │   └── TargetDirectories.txt
│   │   │   │       │   │   │   │       │   ├── .ninja_deps
│   │   │   │       │   │   │   │       │   ├── .ninja_log
│   │   │   │       │   │   │   │       │   ├── additional_project_files.txt
│   │   │   │       │   │   │   │       │   ├── android_gradle_build.json
│   │   │   │       │   │   │   │       │   ├── android_gradle_build_mini.json
│   │   │   │       │   │   │   │       │   ├── build.ninja
│   │   │   │       │   │   │   │       │   ├── build_file_index.txt
│   │   │   │       │   │   │   │       │   ├── cmake_install.cmake
│   │   │   │       │   │   │   │       │   ├── CMakeCache.txt
│   │   │   │       │   │   │   │       │   ├── compile_commands.json
│   │   │   │       │   │   │   │       │   ├── compile_commands.json.bin
│   │   │   │       │   │   │   │       │   ├── configure_fingerprint.bin
│   │   │   │       │   │   │   │       │   ├── metadata_generation_command.txt
│   │   │   │       │   │   │   │       │   ├── prefab_config.json
│   │   │   │       │   │   │   │       │   └── symbol_folder_index.txt
│   │   │   │       │   │   │   │       └── hash_key.txt
│   │   │   │       │   │   │   └── tools
│   │   │   │       │   │   │       ├── profile
│   │   │   │       │   │   │       │   ├── arm64-v8a
│   │   │   │       │   │   │       │   │   └── compile_commands.json
│   │   │   │       │   │   │       │   ├── armeabi-v7a
│   │   │   │       │   │   │       │   │   └── compile_commands.json
│   │   │   │       │   │   │       │   ├── x86
│   │   │   │       │   │   │       │   │   └── compile_commands.json
│   │   │   │       │   │   │       │   └── x86_64
│   │   │   │       │   │   │       │       └── compile_commands.json
│   │   │   │       │   │   │       └── release
│   │   │   │       │   │   │           ├── arm64-v8a
│   │   │   │       │   │   │           │   └── compile_commands.json
│   │   │   │       │   │   │           ├── armeabi-v7a
│   │   │   │       │   │   │           │   └── compile_commands.json
│   │   │   │       │   │   │           ├── x86
│   │   │   │       │   │   │           │   └── compile_commands.json
│   │   │   │       │   │   │           └── x86_64
│   │   │   │       │   │   │               └── compile_commands.json
│   │   │   │       │   │   ├── .gradle
│   │   │   │       │   │   │   ├── 8.9
│   │   │   │       │   │   │   │   ├── checksums
│   │   │   │       │   │   │   │   │   └── checksums.lock
│   │   │   │       │   │   │   │   ├── dependencies-accessors
│   │   │   │       │   │   │   │   │   └── gc.properties
│   │   │   │       │   │   │   │   ├── expanded
│   │   │   │       │   │   │   │   ├── fileChanges
│   │   │   │       │   │   │   │   │   └── last-build.bin
│   │   │   │       │   │   │   │   ├── fileHashes
│   │   │   │       │   │   │   │   │   └── fileHashes.lock
│   │   │   │       │   │   │   │   ├── vcsMetadata
│   │   │   │       │   │   │   │   └── gc.properties
│   │   │   │       │   │   │   ├── buildOutputCleanup
│   │   │   │       │   │   │   │   ├── buildOutputCleanup.lock
│   │   │   │       │   │   │   │   └── cache.properties
│   │   │   │       │   │   │   └── vcs-1
│   │   │   │       │   │   │       └── gc.properties
│   │   │   │       │   │   ├── src
│   │   │   │       │   │   │   └── main
│   │   │   │       │   │   │       ├── java
│   │   │   │       │   │   │       │   └── com
│   │   │   │       │   │   │       │       └── github
│   │   │   │       │   │   │       │           └── dart_lang
│   │   │   │       │   │   │       │               └── jni
│   │   │   │       │   │   │       │                   └── JniPlugin.java
│   │   │   │       │   │   │       └── AndroidManifest.xml
│   │   │   │       │   │   ├── build.gradle
│   │   │   │       │   │   ├── consumer-rules.pro
│   │   │   │       │   │   ├── README.md
│   │   │   │       │   │   └── settings.gradle
│   │   │   │       │   ├── bin
│   │   │   │       │   │   └── setup.dart
│   │   │   │       │   ├── example
│   │   │   │       │   │   ├── android
│   │   │   │       │   │   │   ├── app
│   │   │   │       │   │   │   │   ├── src
│   │   │   │       │   │   │   │   │   ├── debug
│   │   │   │       │   │   │   │   │   │   └── AndroidManifest.xml
│   │   │   │       │   │   │   │   │   ├── main
│   │   │   │       │   │   │   │   │   │   ├── java
│   │   │   │       │   │   │   │   │   │   │   ├── com
│   │   │   │       │   │   │   │   │   │   │   │   └── github
│   │   │   │       │   │   │   │   │   │   │   │       └── dart_lang
│   │   │   │       │   │   │   │   │   │   │   │           └── jni_example
│   │   │   │       │   │   │   │   │   │   │   │               └── Toaster.java
│   │   │   │       │   │   │   │   │   │   │   └── io
│   │   │   │       │   │   │   │   │   │   │       └── flutter
│   │   │   │       │   │   │   │   │   │   │           └── plugins
│   │   │   │       │   │   │   │   │   │   ├── kotlin
│   │   │   │       │   │   │   │   │   │   │   └── dev
│   │   │   │       │   │   │   │   │   │   │       └── dart
│   │   │   │       │   │   │   │   │   │   │           └── jni_example
│   │   │   │       │   │   │   │   │   │   │               └── MainActivity.kt
│   │   │   │       │   │   │   │   │   │   ├── res
│   │   │   │       │   │   │   │   │   │   │   ├── drawable
│   │   │   │       │   │   │   │   │   │   │   │   └── launch_background.xml
│   │   │   │       │   │   │   │   │   │   │   ├── drawable-v21
│   │   │   │       │   │   │   │   │   │   │   │   └── launch_background.xml
│   │   │   │       │   │   │   │   │   │   │   ├── mipmap-hdpi
│   │   │   │       │   │   │   │   │   │   │   │   └── ic_launcher.png
│   │   │   │       │   │   │   │   │   │   │   ├── mipmap-mdpi
│   │   │   │       │   │   │   │   │   │   │   │   └── ic_launcher.png
│   │   │   │       │   │   │   │   │   │   │   ├── mipmap-xhdpi
│   │   │   │       │   │   │   │   │   │   │   │   └── ic_launcher.png
│   │   │   │       │   │   │   │   │   │   │   ├── mipmap-xxhdpi
│   │   │   │       │   │   │   │   │   │   │   │   └── ic_launcher.png
│   │   │   │       │   │   │   │   │   │   │   ├── mipmap-xxxhdpi
│   │   │   │       │   │   │   │   │   │   │   │   └── ic_launcher.png
│   │   │   │       │   │   │   │   │   │   │   ├── values
│   │   │   │       │   │   │   │   │   │   │   │   └── styles.xml
│   │   │   │       │   │   │   │   │   │   │   └── values-night
│   │   │   │       │   │   │   │   │   │   │       └── styles.xml
│   │   │   │       │   │   │   │   │   │   └── AndroidManifest.xml
│   │   │   │       │   │   │   │   │   └── profile
│   │   │   │       │   │   │   │   │       └── AndroidManifest.xml
│   │   │   │       │   │   │   │   └── build.gradle
│   │   │   │       │   │   │   ├── gradle
│   │   │   │       │   │   │   │   └── wrapper
│   │   │   │       │   │   │   │       └── gradle-wrapper.properties
│   │   │   │       │   │   │   ├── build.gradle
│   │   │   │       │   │   │   ├── gradle.properties
│   │   │   │       │   │   │   └── settings.gradle
│   │   │   │       │   │   ├── integration_test
│   │   │   │       │   │   │   └── on_device_jni_test.dart
│   │   │   │       │   │   ├── lib
│   │   │   │       │   │   │   └── main.dart
│   │   │   │       │   │   ├── linux
│   │   │   │       │   │   │   ├── flutter
│   │   │   │       │   │   │   │   └── CMakeLists.txt
│   │   │   │       │   │   │   ├── CMakeLists.txt
│   │   │   │       │   │   │   ├── main.cc
│   │   │   │       │   │   │   ├── my_application.cc
│   │   │   │       │   │   │   └── my_application.h
│   │   │   │       │   │   ├── macos
│   │   │   │       │   │   │   ├── Flutter
│   │   │   │       │   │   │   │   ├── Flutter-Debug.xcconfig
│   │   │   │       │   │   │   │   └── Flutter-Release.xcconfig
│   │   │   │       │   │   │   ├── Runner
│   │   │   │       │   │   │   │   ├── Assets.xcassets
│   │   │   │       │   │   │   │   │   └── AppIcon.appiconset
│   │   │   │       │   │   │   │   │       ├── app_icon_1024.png
│   │   │   │       │   │   │   │   │       ├── app_icon_128.png
│   │   │   │       │   │   │   │   │       ├── app_icon_16.png
│   │   │   │       │   │   │   │   │       ├── app_icon_256.png
│   │   │   │       │   │   │   │   │       ├── app_icon_32.png
│   │   │   │       │   │   │   │   │       ├── app_icon_512.png
│   │   │   │       │   │   │   │   │       ├── app_icon_64.png
│   │   │   │       │   │   │   │   │       └── Contents.json
│   │   │   │       │   │   │   │   ├── Base.lproj
│   │   │   │       │   │   │   │   │   └── MainMenu.xib
│   │   │   │       │   │   │   │   ├── Configs
│   │   │   │       │   │   │   │   │   ├── AppInfo.xcconfig
│   │   │   │       │   │   │   │   │   ├── Debug.xcconfig
│   │   │   │       │   │   │   │   │   ├── Release.xcconfig
│   │   │   │       │   │   │   │   │   └── Warnings.xcconfig
│   │   │   │       │   │   │   │   ├── AppDelegate.swift
│   │   │   │       │   │   │   │   ├── DebugProfile.entitlements
│   │   │   │       │   │   │   │   ├── Info.plist
│   │   │   │       │   │   │   │   ├── MainFlutterWindow.swift
│   │   │   │       │   │   │   │   └── Release.entitlements
│   │   │   │       │   │   │   ├── Runner.xcodeproj
│   │   │   │       │   │   │   │   ├── project.xcworkspace
│   │   │   │       │   │   │   │   │   └── xcshareddata
│   │   │   │       │   │   │   │   │       ├── swiftpm
│   │   │   │       │   │   │   │   │       │   └── configuration
│   │   │   │       │   │   │   │   │       └── IDEWorkspaceChecks.plist
│   │   │   │       │   │   │   │   ├── xcshareddata
│   │   │   │       │   │   │   │   │   └── xcschemes
│   │   │   │       │   │   │   │   │       └── Runner.xcscheme
│   │   │   │       │   │   │   │   └── project.pbxproj
│   │   │   │       │   │   │   ├── Runner.xcworkspace
│   │   │   │       │   │   │   │   ├── xcshareddata
│   │   │   │       │   │   │   │   │   └── IDEWorkspaceChecks.plist
│   │   │   │       │   │   │   │   └── contents.xcworkspacedata
│   │   │   │       │   │   │   └── Podfile
│   │   │   │       │   │   ├── windows
│   │   │   │       │   │   │   ├── flutter
│   │   │   │       │   │   │   │   └── CMakeLists.txt
│   │   │   │       │   │   │   ├── runner
│   │   │   │       │   │   │   │   ├── resources
│   │   │   │       │   │   │   │   │   └── app_icon.ico
│   │   │   │       │   │   │   │   ├── CMakeLists.txt
│   │   │   │       │   │   │   │   ├── flutter_window.cpp
│   │   │   │       │   │   │   │   ├── flutter_window.h
│   │   │   │       │   │   │   │   ├── main.cpp
│   │   │   │       │   │   │   │   ├── resource.h
│   │   │   │       │   │   │   │   ├── runner.exe.manifest
│   │   │   │       │   │   │   │   ├── Runner.rc
│   │   │   │       │   │   │   │   ├── utils.cpp
│   │   │   │       │   │   │   │   ├── utils.h
│   │   │   │       │   │   │   │   ├── win32_window.cpp
│   │   │   │       │   │   │   │   └── win32_window.h
│   │   │   │       │   │   │   └── CMakeLists.txt
│   │   │   │       │   │   ├── analysis_options.yaml
│   │   │   │       │   │   ├── pubspec.yaml
│   │   │   │       │   │   └── README.md
│   │   │   │       │   ├── java
│   │   │   │       │   │   ├── gradle
│   │   │   │       │   │   │   ├── wrapper
│   │   │   │       │   │   │   │   ├── gradle-wrapper.jar
│   │   │   │       │   │   │   │   └── gradle-wrapper.properties
│   │   │   │       │   │   │   └── libs.versions.toml
│   │   │   │       │   │   ├── src
│   │   │   │       │   │   │   └── main
│   │   │   │       │   │   │       └── java
│   │   │   │       │   │   │           └── com
│   │   │   │       │   │   │               └── github
│   │   │   │       │   │   │                   └── dart_lang
│   │   │   │       │   │   │                       └── jni
│   │   │   │       │   │   │                           ├── JniUtils.java
│   │   │   │       │   │   │                           ├── PortCleaner.java
│   │   │   │       │   │   │                           ├── PortContinuation.java
│   │   │   │       │   │   │                           └── PortProxyBuilder.java
│   │   │   │       │   │   ├── build.gradle.kts
│   │   │   │       │   │   ├── gradlew
│   │   │   │       │   │   ├── gradlew.bat
│   │   │   │       │   │   ├── README.md
│   │   │   │       │   │   └── settings.gradle.kts
│   │   │   │       │   ├── lib
│   │   │   │       │   │   ├── src
│   │   │   │       │   │   │   ├── build_util
│   │   │   │       │   │   │   │   └── build_util.dart
│   │   │   │       │   │   │   ├── lang
│   │   │   │       │   │   │   │   ├── jboolean.dart
│   │   │   │       │   │   │   │   ├── jbyte.dart
│   │   │   │       │   │   │   │   ├── jcharacter.dart
│   │   │   │       │   │   │   │   ├── jdouble.dart
│   │   │   │       │   │   │   │   ├── jfloat.dart
│   │   │   │       │   │   │   │   ├── jinteger.dart
│   │   │   │       │   │   │   │   ├── jlong.dart
│   │   │   │       │   │   │   │   ├── jnumber.dart
│   │   │   │       │   │   │   │   ├── jshort.dart
│   │   │   │       │   │   │   │   ├── jstring.dart
│   │   │   │       │   │   │   │   └── lang.dart
│   │   │   │       │   │   │   ├── nio
│   │   │   │       │   │   │   │   ├── jbuffer.dart
│   │   │   │       │   │   │   │   ├── jbyte_buffer.dart
│   │   │   │       │   │   │   │   └── nio.dart
│   │   │   │       │   │   │   ├── third_party
│   │   │   │       │   │   │   │   ├── generated_bindings.dart
│   │   │   │       │   │   │   │   ├── global_env_extensions.dart
│   │   │   │       │   │   │   │   └── jni_bindings_generated.dart
│   │   │   │       │   │   │   ├── util
│   │   │   │       │   │   │   │   ├── jiterator.dart
│   │   │   │       │   │   │   │   ├── jlist.dart
│   │   │   │       │   │   │   │   ├── jmap.dart
│   │   │   │       │   │   │   │   ├── jset.dart
│   │   │   │       │   │   │   │   └── util.dart
│   │   │   │       │   │   │   ├── accessors.dart
│   │   │   │       │   │   │   ├── core_bindings.dart
│   │   │   │       │   │   │   ├── errors.dart
│   │   │   │       │   │   │   ├── jarray.dart
│   │   │   │       │   │   │   ├── jclass.dart
│   │   │   │       │   │   │   ├── jimplementer.dart
│   │   │   │       │   │   │   ├── jni.dart
│   │   │   │       │   │   │   ├── jobject.dart
│   │   │   │       │   │   │   ├── jprimitives.dart
│   │   │   │       │   │   │   ├── jreference.dart
│   │   │   │       │   │   │   ├── jvalues.dart
│   │   │   │       │   │   │   ├── kotlin.dart
│   │   │   │       │   │   │   ├── method_invocation.dart
│   │   │   │       │   │   │   ├── primitive_jarrays.dart
│   │   │   │       │   │   │   ├── types.dart
│   │   │   │       │   │   │   └── version_check.dart
│   │   │   │       │   │   ├── _internal.dart
│   │   │   │       │   │   ├── jni.dart
│   │   │   │       │   │   └── jni_symbols.yaml
│   │   │   │       │   ├── linux
│   │   │   │       │   │   └── CMakeLists.txt
│   │   │   │       │   ├── src
│   │   │   │       │   │   ├── include
│   │   │   │       │   │   │   ├── bin
│   │   │   │       │   │   │   │   ├── dart_io_api.h
│   │   │   │       │   │   │   │   └── native_assets_api.h
│   │   │   │       │   │   │   ├── internal
│   │   │   │       │   │   │   │   └── dart_api_dl_impl.h
│   │   │   │       │   │   │   ├── analyze_snapshot_api.h
│   │   │   │       │   │   │   ├── BUILD.gn
│   │   │   │       │   │   │   ├── dart_api.h
│   │   │   │       │   │   │   ├── dart_api_dl.c
│   │   │   │       │   │   │   ├── dart_api_dl.h
│   │   │   │       │   │   │   ├── dart_embedder_api.h
│   │   │   │       │   │   │   ├── dart_native_api.h
│   │   │   │       │   │   │   ├── dart_tools_api.h
│   │   │   │       │   │   │   └── dart_version.h
│   │   │   │       │   │   ├── third_party
│   │   │   │       │   │   │   ├── global_jni_env.c
│   │   │   │       │   │   │   └── global_jni_env.h
│   │   │   │       │   │   ├── CMakeLists.txt
│   │   │   │       │   │   ├── dartjni.c
│   │   │   │       │   │   ├── dartjni.h
│   │   │   │       │   │   ├── jni_constants.h
│   │   │   │       │   │   └── README.md
│   │   │   │       │   ├── test
│   │   │   │       │   │   ├── test_util
│   │   │   │       │   │   │   └── test_util.dart
│   │   │   │       │   │   ├── version_check
│   │   │   │       │   │   │   ├── fail_major.dart
│   │   │   │       │   │   │   ├── fail_minor.dart
│   │   │   │       │   │   │   └── pass.dart
│   │   │   │       │   │   ├── boxed_test.dart
│   │   │   │       │   │   ├── debug_release_test.dart
│   │   │   │       │   │   ├── exception_test.dart
│   │   │   │       │   │   ├── global_env_test.dart
│   │   │   │       │   │   ├── isolate_test.dart
│   │   │   │       │   │   ├── jarray_test.dart
│   │   │   │       │   │   ├── jbyte_buffer_test.dart
│   │   │   │       │   │   ├── jlist_test.dart
│   │   │   │       │   │   ├── jmap_test.dart
│   │   │   │       │   │   ├── jobject_test.dart
│   │   │   │       │   │   ├── jset_test.dart
│   │   │   │       │   │   ├── jstring_test.dart
│   │   │   │       │   │   ├── load_test.dart
│   │   │   │       │   │   ├── no_such_method_test.dart
│   │   │   │       │   │   └── version_check_test.dart
│   │   │   │       │   ├── third_party
│   │   │   │       │   │   └── jni.h
│   │   │   │       │   ├── tool
│   │   │   │       │   │   ├── wrapper_generators
│   │   │   │       │   │   │   ├── ffigen_util.dart
│   │   │   │       │   │   │   ├── generate_c_extensions.dart
│   │   │   │       │   │   │   ├── generate_dart_extensions.dart
│   │   │   │       │   │   │   ├── generate_helper_functions.dart
│   │   │   │       │   │   │   └── logging.dart
│   │   │   │       │   │   ├── generate_ffi_bindings.dart
│   │   │   │       │   │   ├── generate_ide_files.dart
│   │   │   │       │   │   ├── generate_jni_bindings.dart
│   │   │   │       │   │   └── generate_primitive_arrays.dart
│   │   │   │       │   ├── windows
│   │   │   │       │   │   └── CMakeLists.txt
│   │   │   │       │   ├── analysis_options.yaml
│   │   │   │       │   ├── CHANGELOG.md
│   │   │   │       │   ├── dart_test.yaml
│   │   │   │       │   ├── ffigen.yaml
│   │   │   │       │   ├── ffigen_exts.yaml
│   │   │   │       │   ├── LICENSE
│   │   │   │       │   ├── pubspec.yaml
│   │   │   │       │   └── README.md
│   │   │   │       ├── path_provider_windows
│   │   │   │       │   ├── example
│   │   │   │       │   │   ├── integration_test
│   │   │   │       │   │   │   └── path_provider_test.dart
│   │   │   │       │   │   ├── lib
│   │   │   │       │   │   │   └── main.dart
│   │   │   │       │   │   ├── test_driver
│   │   │   │       │   │   │   └── integration_test.dart
│   │   │   │       │   │   ├── windows
│   │   │   │       │   │   │   ├── flutter
│   │   │   │       │   │   │   │   ├── CMakeLists.txt
│   │   │   │       │   │   │   │   └── generated_plugins.cmake
│   │   │   │       │   │   │   ├── runner
│   │   │   │       │   │   │   │   ├── resources
│   │   │   │       │   │   │   │   │   └── app_icon.ico
│   │   │   │       │   │   │   │   ├── CMakeLists.txt
│   │   │   │       │   │   │   │   ├── flutter_window.cpp
│   │   │   │       │   │   │   │   ├── flutter_window.h
│   │   │   │       │   │   │   │   ├── main.cpp
│   │   │   │       │   │   │   │   ├── resource.h
│   │   │   │       │   │   │   │   ├── run_loop.cpp
│   │   │   │       │   │   │   │   ├── run_loop.h
│   │   │   │       │   │   │   │   ├── runner.exe.manifest
│   │   │   │       │   │   │   │   ├── Runner.rc
│   │   │   │       │   │   │   │   ├── utils.cpp
│   │   │   │       │   │   │   │   ├── utils.h
│   │   │   │       │   │   │   │   ├── win32_window.cpp
│   │   │   │       │   │   │   │   └── win32_window.h
│   │   │   │       │   │   │   └── CMakeLists.txt
│   │   │   │       │   │   ├── pubspec.yaml
│   │   │   │       │   │   └── README.md
│   │   │   │       │   ├── lib
│   │   │   │       │   │   ├── src
│   │   │   │       │   │   │   ├── folders.dart
│   │   │   │       │   │   │   ├── folders_stub.dart
│   │   │   │       │   │   │   ├── guid.dart
│   │   │   │       │   │   │   ├── path_provider_windows_real.dart
│   │   │   │       │   │   │   ├── path_provider_windows_stub.dart
│   │   │   │       │   │   │   └── win32_wrappers.dart
│   │   │   │       │   │   └── path_provider_windows.dart
│   │   │   │       │   ├── test
│   │   │   │       │   │   ├── guid_test.dart
│   │   │   │       │   │   └── path_provider_windows_test.dart
│   │   │   │       │   ├── AUTHORS
│   │   │   │       │   ├── CHANGELOG.md
│   │   │   │       │   ├── LICENSE
│   │   │   │       │   ├── pubspec.yaml
│   │   │   │       │   └── README.md
│   │   │   │       ├── permission_handler_windows
│   │   │   │       │   ├── example
│   │   │   │       │   │   ├── lib
│   │   │   │       │   │   │   └── main.dart
│   │   │   │       │   │   ├── res
│   │   │   │       │   │   │   └── images
│   │   │   │       │   │   │       ├── baseflow_logo_def_light-02.png
│   │   │   │       │   │   │       ├── poweredByBaseflowLogoLight.png
│   │   │   │       │   │   │       ├── poweredByBaseflowLogoLight@2x.png
│   │   │   │       │   │   │       └── poweredByBaseflowLogoLight@3x.png
│   │   │   │       │   │   ├── windows
│   │   │   │       │   │   │   ├── flutter
│   │   │   │       │   │   │   │   ├── CMakeLists.txt
│   │   │   │       │   │   │   │   ├── generated_plugin_registrant.cc
│   │   │   │       │   │   │   │   ├── generated_plugin_registrant.h
│   │   │   │       │   │   │   │   └── generated_plugins.cmake
│   │   │   │       │   │   │   ├── runner
│   │   │   │       │   │   │   │   ├── resources
│   │   │   │       │   │   │   │   │   └── app_icon.ico
│   │   │   │       │   │   │   │   ├── CMakeLists.txt
│   │   │   │       │   │   │   │   ├── flutter_window.cpp
│   │   │   │       │   │   │   │   ├── flutter_window.h
│   │   │   │       │   │   │   │   ├── main.cpp
│   │   │   │       │   │   │   │   ├── resource.h
│   │   │   │       │   │   │   │   ├── runner.exe.manifest
│   │   │   │       │   │   │   │   ├── Runner.rc
│   │   │   │       │   │   │   │   ├── utils.cpp
│   │   │   │       │   │   │   │   ├── utils.h
│   │   │   │       │   │   │   │   ├── win32_window.cpp
│   │   │   │       │   │   │   │   └── win32_window.h
│   │   │   │       │   │   │   └── CMakeLists.txt
│   │   │   │       │   │   ├── pubspec.yaml
│   │   │   │       │   │   └── README.md
│   │   │   │       │   ├── windows
│   │   │   │       │   │   ├── include
│   │   │   │       │   │   │   └── permission_handler_windows
│   │   │   │       │   │   │       └── permission_handler_windows_plugin.h
│   │   │   │       │   │   ├── CMakeLists.txt
│   │   │   │       │   │   ├── permission_constants.h
│   │   │   │       │   │   └── permission_handler_windows_plugin.cpp
│   │   │   │       │   ├── AUTHORS
│   │   │   │       │   ├── CHANGELOG.md
│   │   │   │       │   ├── LICENSE
│   │   │   │       │   ├── pubspec.yaml
│   │   │   │       │   └── README.md
│   │   │   │       └── shared_preferences_windows
│   │   │   │           ├── example
│   │   │   │           │   ├── integration_test
│   │   │   │           │   │   └── shared_preferences_test.dart
│   │   │   │           │   ├── lib
│   │   │   │           │   │   └── main.dart
│   │   │   │           │   ├── test_driver
│   │   │   │           │   │   └── integration_test.dart
│   │   │   │           │   ├── windows
│   │   │   │           │   │   ├── flutter
│   │   │   │           │   │   │   ├── CMakeLists.txt
│   │   │   │           │   │   │   └── generated_plugins.cmake
│   │   │   │           │   │   ├── runner
│   │   │   │           │   │   │   ├── resources
│   │   │   │           │   │   │   │   └── app_icon.ico
│   │   │   │           │   │   │   ├── CMakeLists.txt
│   │   │   │           │   │   │   ├── flutter_window.cpp
│   │   │   │           │   │   │   ├── flutter_window.h
│   │   │   │           │   │   │   ├── main.cpp
│   │   │   │           │   │   │   ├── resource.h
│   │   │   │           │   │   │   ├── run_loop.cpp
│   │   │   │           │   │   │   ├── run_loop.h
│   │   │   │           │   │   │   ├── runner.exe.manifest
│   │   │   │           │   │   │   ├── Runner.rc
│   │   │   │           │   │   │   ├── utils.cpp
│   │   │   │           │   │   │   ├── utils.h
│   │   │   │           │   │   │   ├── win32_window.cpp
│   │   │   │           │   │   │   └── win32_window.h
│   │   │   │           │   │   └── CMakeLists.txt
│   │   │   │           │   ├── AUTHORS
│   │   │   │           │   ├── LICENSE
│   │   │   │           │   ├── pubspec.yaml
│   │   │   │           │   └── README.md
│   │   │   │           ├── lib
│   │   │   │           │   └── shared_preferences_windows.dart
│   │   │   │           ├── test
│   │   │   │           │   ├── fake_path_provider_windows.dart
│   │   │   │           │   ├── legacy_shared_preferences_windows_test.dart
│   │   │   │           │   └── shared_preferences_windows_async_test.dart
│   │   │   │           ├── AUTHORS
│   │   │   │           ├── CHANGELOG.md
│   │   │   │           ├── LICENSE
│   │   │   │           ├── pubspec.yaml
│   │   │   │           └── README.md
│   │   │   ├── CMakeLists.txt
│   │   │   ├── generated_plugin_registrant.cc
│   │   │   ├── generated_plugin_registrant.h
│   │   │   └── generated_plugins.cmake
│   │   ├── runner
│   │   │   ├── resources
│   │   │   │   └── app_icon.ico
│   │   │   ├── CMakeLists.txt
│   │   │   ├── flutter_window.cpp
│   │   │   ├── flutter_window.h
│   │   │   ├── main.cpp
│   │   │   ├── resource.h
│   │   │   ├── runner.exe.manifest
│   │   │   ├── Runner.rc
│   │   │   ├── utils.cpp
│   │   │   ├── utils.h
│   │   │   ├── win32_window.cpp
│   │   │   └── win32_window.h
│   │   ├── .gitignore
│   │   └── CMakeLists.txt
│   ├── .flutter-plugins-dependencies
│   ├── .gitignore
│   ├── .metadata
│   ├── analysis_options.yaml
│   ├── core_infra_dump.txt
│   ├── customer_feature_dump.txt
│   ├── DESIGN.md
│   ├── flutter_01.png
│   ├── flutter_02.png
│   ├── flutter_03.png
│   ├── flutter_04.png
│   ├── flutter_05.png
│   ├── flutter_06.png
│   ├── flutter_07.png
│   ├── flutter_08.png
│   ├── flutter_09.png
│   ├── flutter_10.png
│   ├── flutter_100.png
│   ├── flutter_101.png
│   ├── flutter_102.png
│   ├── flutter_103.png
│   ├── flutter_104.png
│   ├── flutter_105.png
│   ├── flutter_106.png
│   ├── flutter_107.png
│   ├── flutter_108.png
│   ├── flutter_109.png
│   ├── flutter_11.png
│   ├── flutter_110.png
│   ├── flutter_111.png
│   ├── flutter_112.png
│   ├── flutter_113.png
│   ├── flutter_114.png
│   ├── flutter_115.png
│   ├── flutter_116.png
│   ├── flutter_117.png
│   ├── flutter_118.png
│   ├── flutter_119.png
│   ├── flutter_12.png
│   ├── flutter_120.png
│   ├── flutter_121.png
│   ├── flutter_122.png
│   ├── flutter_123.png
│   ├── flutter_124.png
│   ├── flutter_125.png
│   ├── flutter_126.png
│   ├── flutter_127.png
│   ├── flutter_128.png
│   ├── flutter_129.png
│   ├── flutter_13.png
│   ├── flutter_130.png
│   ├── flutter_131.png
│   ├── flutter_132.png
│   ├── flutter_14.png
│   ├── flutter_15.png
│   ├── flutter_16.png
│   ├── flutter_17.png
│   ├── flutter_18.png
│   ├── flutter_19.png
│   ├── flutter_20.png
│   ├── flutter_21.png
│   ├── flutter_22.png
│   ├── flutter_23.png
│   ├── flutter_24.png
│   ├── flutter_25.png
│   ├── flutter_26.png
│   ├── flutter_27.png
│   ├── flutter_28.png
│   ├── flutter_29.png
│   ├── flutter_30.png
│   ├── flutter_31.png
│   ├── flutter_32.png
│   ├── flutter_33.png
│   ├── flutter_34.png
│   ├── flutter_35.png
│   ├── flutter_36.png
│   ├── flutter_37.png
│   ├── flutter_38.png
│   ├── flutter_39.png
│   ├── flutter_40.png
│   ├── flutter_41.png
│   ├── flutter_42.png
│   ├── flutter_43.png
│   ├── flutter_44.png
│   ├── flutter_45.png
│   ├── flutter_46.png
│   ├── flutter_47.png
│   ├── flutter_48.png
│   ├── flutter_49.png
│   ├── flutter_50.png
│   ├── flutter_51.png
│   ├── flutter_52.png
│   ├── flutter_53.png
│   ├── flutter_54.png
│   ├── flutter_55.png
│   ├── flutter_56.png
│   ├── flutter_57.png
│   ├── flutter_58.png
│   ├── flutter_59.png
│   ├── flutter_60.png
│   ├── flutter_61.png
│   ├── flutter_62.png
│   ├── flutter_63.png
│   ├── flutter_64.png
│   ├── flutter_65.png
│   ├── flutter_66.png
│   ├── flutter_67.png
│   ├── flutter_68.png
│   ├── flutter_69.png
│   ├── flutter_70.png
│   ├── flutter_71.png
│   ├── flutter_72.png
│   ├── flutter_73.png
│   ├── flutter_74.png
│   ├── flutter_75.png
│   ├── flutter_76.png
│   ├── flutter_77.png
│   ├── flutter_78.png
│   ├── flutter_79.png
│   ├── flutter_80.png
│   ├── flutter_81.png
│   ├── flutter_82.png
│   ├── flutter_83.png
│   ├── flutter_84.png
│   ├── flutter_85.png
│   ├── flutter_86.png
│   ├── flutter_87.png
│   ├── flutter_88.png
│   ├── flutter_89.png
│   ├── flutter_90.png
│   ├── flutter_91.png
│   ├── flutter_92.png
│   ├── flutter_93.png
│   ├── flutter_94.png
│   ├── flutter_95.png
│   ├── flutter_96.png
│   ├── flutter_97.png
│   ├── flutter_98.png
│   ├── flutter_99.png
│   ├── l10n.yaml
│   ├── pubspec.lock
│   ├── pubspec.yaml
│   ├── README.md
│   └── servicehub_frontend.iml
├── stitch_servicehub
│   ├── color_exploration.html
│   ├── color_exploration.png
│   ├── screen.html
│   └── screenshot.png
├── BACKEND_CONTRACT.md
├── CONTINUATION_HANDOFF.md
├── PROJECT_FILE_STRUCTURE.md
├── servicehub.zip
├── SERVICEHUB_FINAL_IMPLEMENTATION_GUIDE_ENHANCED.md
└── SERVICEHUB_PROJECT_TREE.md
