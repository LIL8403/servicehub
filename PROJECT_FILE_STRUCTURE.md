# ServiceHUB Project File Structure

**Snapshot:** 2026-10-02  
This is the application-source structure for the Laravel backend and Flutter frontend. Dependency/vendor folders, Flutter build output, Laravel cache/log output, and MongoDB backup payloads are intentionally summarized rather than expanded.

```text
DIGITAL-SERVICE-MARKETPLACE/
├── BACKEND_CONTRACT.md
├── CONTINUATION_HANDOFF.md
├── PROJECT_FILE_STRUCTURE.md
├── SERVICEHUB_FINAL_IMPLEMENTATION_GUIDE_ENHANCED.md
├── servicehub/                                      # Laravel API
│   ├── artisan
│   ├── composer.json / composer.lock
│   ├── package.json / package-lock.json / vite.config.js
│   ├── phpunit.xml
│   ├── .env / .env.example
│   ├── api_routes.txt
│   ├── tracking_backend_dump.txt
│   ├── tracking_sample_response.json
│   ├── app/
│   │   ├── Ai/Agents/
│   │   │   ├── AnomalyDetector.php
│   │   │   ├── ArtisanRecommender.php
│   │   │   ├── QuotationAnalyzer.php
│   │   │   └── RequestUnderstandingAgent.php
│   │   ├── Console/Commands/
│   │   │   ├── ExpireArtisanResponses.php
│   │   │   └── ExpirePendingDisputeResolutions.php
│   │   ├── Contracts/Payments/CamPayGateway.php
│   │   ├── Enums/
│   │   │   ├── AccountStatus.php
│   │   │   ├── DisputeStatus.php
│   │   │   ├── PaymentStatus.php
│   │   │   ├── PayoutStatus.php
│   │   │   ├── ServiceRequestStatus.php
│   │   │   ├── UrgencyLevel.php
│   │   │   └── VerificationStatus.php
│   │   ├── Exceptions/RefundNotSupportedException.php
│   │   ├── Http/
│   │   │   ├── Controllers/Api/
│   │   │   │   ├── Admin/{ArtisanVerification,Dispute,PlatformSettings,Reporting,ServiceCategory,Service,UserManagement}Controller.php
│   │   │   │   ├── Auth/AuthController.php
│   │   │   │   ├── {Ai,ArtisanDiscovery,ArtisanRequest,ArtisanServiceOffering,CamPayWebhook,Catalog,Conversation,CustomerConversation,CustomerPayment,Dispute,DisputeEvidence,Notification,Payment,Profile,Review,ServiceRequest,User,UserRole}Controller.php
│   │   │   ├── Middleware/{EnsureActiveAccount,RequirePermission,RequireRole}.php
│   │   │   └── Requests/
│   │   │       ├── Admin/{CancelDisputeResolution,RejectArtisan,ResolveDispute,StoreServiceCategory,StoreServiceRequest,UpdateAccountStatus,UpdateCommissionRate,UpdateDispute,UpdateServiceCategory,UpdateServiceRequest}Request.php
│   │   │       ├── Artisan/{DeclineRequest,StoreServiceOffering,UpdateServiceOffering}Request.php
│   │   │       ├── Auth/{ArtisanRegistration,ChangePassword,CustomerRegistration,ForgotPassword,Login,ResetPassword}Request.php
│   │   │       ├── Conversation/StoreMessageRequest.php
│   │   │       ├── Dispute/{AddDisputeEvidence,OpenDispute}Request.php
│   │   │       ├── Payment/InitiatePaymentRequest.php
│   │   │       ├── Profile/{StoreProfilePhoto,UpdateArtisanProfile,UpdateCustomerProfile}Request.php
│   │   │       ├── Review/StoreReviewRequest.php
│   │   │       ├── ServiceRequest/{ApproveMaterials,CancelServiceRequest,ChangeArtisan,CompleteInspection,ProposeMaterials,RejectQuotation,ReportCompletion,ScheduleInspection,SelectArtisan,StoreQuotation,StoreServiceRequest,UpdateServiceRequest}Request.php
│   │   │       └── User/{BecomeArtisan,SwitchRole}Request.php
│   │   ├── Jobs/{AnalyzeQuotationJob,DetectPaymentAnomalyJob}.php
│   │   ├── Models/{Administrator,Artisan,ArtisanProfile,AuditLog,Conversation,Customer,Dispute,Message,Payment,Payout,PersonalAccessToken,PlatformNotification,PlatformSetting,ResolutionReference,Review,Service,ServiceCategory,ServiceRequest,User}.php
│   │   ├── Notifications/VerifyEmailNotification.php
│   │   ├── Providers/AppServiceProvider.php
│   │   └── Services/
│   │       ├── Ai/{AiOrchestrationService,ArtisanRankingService}.php
│   │       ├── Artisan/ArtisanMatchingService.php
│   │       ├── Location/GeocodingService.php
│   │       ├── Payments/{CamPayHttpGateway,SimulatedCamPayGateway}.php
│   │       ├── Platform/PlatformSettingsService.php
│   │       ├── ServiceRequest/{ServiceRequestLifecycleService,ServiceRequestTrackingService}.php
│   │       └── {AdminReporting,AdminUserManagement,ArtisanVerification,AuditLog,Auth,Catalog,Conversation,DisputeResolution,Dispute,Payment,PlatformNotification,ProfilePhoto,Review,ServiceRequestMedia,ServiceRequest,UserRole}Service.php
│   ├── bootstrap/{app.php,providers.php,cache/}
│   ├── config/{ai,api,app,auth,cache,database,filesystems,logging,mail,queue,roles,sanctum,security,services,session,verification}.php
│   ├── database/
│   │   ├── factories/{ServiceRequestFactory,UserFactory}.php
│   │   ├── migrations/
│   │   │   ├── 0001_01_01_000000_create_users_table.php
│   │   │   ├── 0001_01_01_000001_create_cache_table.php
│   │   │   ├── 0001_01_01_000002_create_jobs_table.php
│   │   │   ├── 2026_08_11_{112502_create_personal_access_tokens,133958_create_artisan_profiles,135232_create_service_categories,135257_create_services}_table.php
│   │   │   ├── 2026_09_09_{000000_add_core_marketplace_indexes,000001_align_artisan_verification_statuses,000002_add_artisan_discovery_indexes,000003_correct_artisan_offering_index_field,000004_convert_embedded_json_to_bson_documents,000005_create_service_requests_collection,000006_reconcile_mongodb_indexes}.php
│   │   │   ├── 2026_09_10_{000000_create_payments_collection,000001_add_artisan_payout_phone_index,000002_create_payouts_collection,000003_add_service_request_payment_index}.php
│   │   │   ├── 2026_09_12_000000..000008_* collections and dispute indexes
│   │   │   ├── 2026_09_14_000000_convert_json_array_casts_to_bson_arrays.php
│   │   │   ├── 2026_09_23_000000_create_separate_user_role_collections.php
│   │   │   └── 2026_09_29_000000_add_service_request_selection_lifecycle_indexes.php
│   │   └── seeders/{Artisan,Database,DevelopmentUser,PlatformSettings,ServiceCatalog}Seeder.php
│   ├── public/{index.php,favicon.ico,robots.txt}
│   ├── resources/{css/app.css,js/app.js,views/welcome.blade.php}
│   ├── routes/{api.php,console.php,web.php}
│   ├── storage/                                      # runtime private files/cache/logs; not source
│   ├── backups/servicehub/                            # BSON database backup; not application source
│   └── tests/
│       ├── Feature/{AdminReporting,AdminUserManagement,ArtisanDiscovery,ArtisanGeospatialDiscovery,ArtisanPayoutPhone,ArtisanRanking,Authentication,CamPayHttpGateway,CommissionAndDisputeResolution,CompletionPayout,ConcurrentArtisanSelection,Conversation,CustomerProfilePhoto,Dispute,DualRoleUser,EmailVerification,GeocodingService,InspectionAndQuotation,MaterialsApproval,NotificationApi,PasswordManagement,PasswordResetSecurity,PaymentIdempotency,PaymentInitiation,ProfileAndVerification,RateLimiting,Review,RoleAuthorization,ServiceCatalog,ServiceRequestGeocoding,ServiceRequestImage,ServiceRequestLifecycle,ServiceRequest}Test.php
│       ├── Unit/ExampleTest.php
│       ├── Pest.php
│       └── TestCase.php
│
└── servicehub_frontend/                               # Flutter app
    ├── pubspec.yaml / pubspec.lock / analysis_options.yaml
    ├── DESIGN.md / README.md
    ├── core_infra_dump.txt / customer_feature_dump.txt
    ├── assets/brand/{app_icon_1024,favicon_16,favicon_32,logo_dark_bg,logo_light_bg}.png
    ├── assets/brand/{logo_monochrome,logo_primary,logo_stacked,logo_symbol}.svg
    ├── android/                                       # Android platform project
    ├── web/                                           # Flutter Web shell/assets
    ├── windows/                                       # Windows platform runner
    ├── test/widget_test.dart
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── api/{api_exception,api_service,authenticated_image_client,token_storage}.dart
        │   ├── constants/api_constants.dart
        │   ├── localization/{locale_provider,locale_storage}.dart
        │   ├── location/{location_permission_dialog,location_providers,location_service}.dart
        │   ├── routing/app_routes.dart
        │   └── theme/app_theme.dart
        ├── l10n/{app_en,app_fr,app_localizations,app_localizations_en,app_localizations_fr}.dart|arb
        ├── ui/core/
        │   ├── router/{app_router,auth_redirect}.dart
        │   └── theme/{app_colors,app_radii,app_shadows,app_spacing,app_theme,app_typography}.dart
        └── features/
            ├── auth/
            │   ├── data/repositories/{auth_exception,auth_repository}.dart
            │   ├── domain/models/{auth_response,user}.dart
            │   └── presentation/{pages/{login,register}_page.dart,providers/auth_providers.dart,view_models/{login,register}_view_model.dart}
            ├── customer/
            │   ├── data/repositories/{artisan_directory,artisan_selection,conversation,customer_conversations,customer_payments,dispute,payment,quotation,review,service_request,service_request_tracking}_repository.dart
            │   ├── domain/enums/{service_request_status,urgency_level}.dart
            │   ├── domain/models/{artisan_directory_entry,artisan_summary,conversation,conversation_summary,eligible_artisans_response,message,payment_record,service_category,service_request,service_request_draft,service_request_tracking}.dart
            │   └── presentation/
            │       ├── pages/{artisan_profile,artisan_public_profile,artisan_selection,conversation,create_request,customer_discover_tab,customer_home_page,customer_home_tab,customer_messages_tab,customer_payment_history,customer_profile_tab,customer_requests_tab,customer_shell,leave_review,report_issue,request_sent,request_success,request_tracking,service_categories}_page.dart
            │       ├── providers/{artisan_directory,artisan_selection,conversation,create_request,customer_conversations,customer_payments,dispute,my_requests,payment,quotation,request_tracking,review,service_catalog,service_request_tracking,submit_request}_providers.dart
            │       └── widgets/
            │           ├── tracking/{artisan_accepted_view,awaiting_artisan_selection_view,awaiting_confirmation_view,booked_view,cancelled_view,completed_view,disputed_view,in_progress_view,no_artisan_available_view,payment_pending_view,pending_artisan_response_view,quotation_received_view}.dart
            │           ├── tracking/{info_callout_card,request_details_card,request_glance_card,status_hero_card,tracking_actions,tracking_app_bar,tracking_status_badge,tracking_timeline}.dart
            │           ├── tracking/sections/inspection_schedule_section.dart
            │           ├── wizard/{ai_assist_card,date_picker_row,photo_upload_row,review_card,step_1_describe,step_2_location,step_3_schedule,step_4_review,time_window_pickers,urgency_radio_list,wizard_progress}.dart
            │           └── shared customer widgets: ai_recommended_card, artisan_avatar, artisan_card, artisan_chip, category_card, compact_artisan_row, customer_search_bar, featured_artisan_card, login_prompt_sheet, quick_action_tile, request_progress_stepper, request_status_chip, selection_confirmation_sheet, service_category_grid_card
            ├── artisan/
            │   ├── data/repositories/{artisan_profile,artisan_request,artisan_service_offering,artisan_verification}_repository.dart
            │   ├── domain/models/{artisan_request_summary,verification_document_type,verification_status}.dart
            │   └── presentation/
            │       ├── pages/{artisan_completion_report,artisan_earnings,artisan_earnings_tab,artisan_home_tab,artisan_inspection_complete,artisan_materials_form,artisan_messages_tab,artisan_profile_edit,artisan_profile_tab,artisan_quotation_form,artisan_report_completion,artisan_request_detail,artisan_requests_tab,artisan_service_offerings,artisan_shell,artisan_verification}_page.dart
            │       ├── providers/{artisan_earnings,artisan_profile,artisan_request,artisan_service_offering,artisan_verification}_providers.dart
            │       └── widgets/{artisan_earnings_summary,artisan_request_card,artisan_status_badge,decline_request_dialog,earnings_summary_card,material_row_editor,money_text_field,verification_status_card}.dart
            ├── admin/
            │   ├── data/repositories/{admin_dispute,admin_reporting,admin_user,admin_verification}_repository.dart
            │   ├── domain/models/{admin_artisan_application,admin_dashboard_metrics,admin_dispute_summary,admin_user_summary}.dart
            │   └── presentation/
            │       ├── pages/{admin_catalog,admin_dashboard,admin_dispute_detail,admin_dispute_queue,admin_reports,admin_users,admin_verification_detail,admin_verification_queue}_page.dart
            │       └── providers/{admin_dispute,admin_reporting,admin_user,admin_verification}_providers.dart
            ├── landing/presentation/{pages/landing_page.dart,widgets/{language_selector,trust_block}.dart}
            ├── shared/artisan_discovery/{data,domain,presentation}/
            └── splash/presentation/pages/splash_page.dart
```

## Generated and local-only content

- Do not edit `vendor/`, `node_modules/`, `.dart_tool/`, `build/`, Laravel `storage/framework/`, or platform-generated registrants by hand.
- `servicehub/backups/servicehub/` contains BSON backup data and is not a replacement for migrations or seeders.
- `.env` may contain secrets and is intentionally not described beyond its path.
- Refresh this inventory after adding, moving, or removing source modules.
