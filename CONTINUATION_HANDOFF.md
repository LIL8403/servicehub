# ServiceHUB Continuation Handoff

**Generated:** 2026-10-02  
**Purpose:** A maintained map of the live source required to continue ServiceHUB safely. Read this before changing application behaviour. This document is a living map, not an immutable specification; update it whenever the project evolves.

## 1. Repository Map

```text
DIGITAL-SERVICE-MARKETPLACE/
├── SERVICEHUB_FINAL_IMPLEMENTATION_GUIDE_ENHANCED.md  # approved product and architecture rules
├── BACKEND_CONTRACT.md                                # code-derived API/model reference; refresh after API changes
├── servicehub/                                        # Laravel 13 + MongoDB API
│   ├── app/                                           # domain models, services, HTTP layer, AI agents
│   ├── routes/api.php                                 # authoritative REST route registration
│   ├── routes/console.php                             # scheduler registration
│   ├── database/migrations/                           # MongoDB collections and indexes
│   ├── database/seeders/                              # local catalog/settings/development data
│   └── tests/Feature/                                 # backend behavioural tests
├── servicehub_frontend/                               # Flutter mobile/web application
│   ├── lib/core/                                      # API client, storage, location, shared infrastructure
│   ├── lib/features/                                  # feature-first MVVM implementation
│   ├── lib/ui/core/                                   # router, design tokens and shared app theme and logo
│   └── assets/brand/                                  
```

## 2. Non-Negotiable Product Rules

Source: [`SERVICEHUB_FINAL_IMPLEMENTATION_GUIDE_ENHANCED.md`](SERVICEHUB_FINAL_IMPLEMENTATION_GUIDE_ENHANCED.md).

- Laravel REST API + MongoDB is the backend architecture; Flutter is the client.
- CamPay is the only approved payment integration. Credentials remain server-side.
- A `User` is separate from `Customer`, `Artisan`, and `Administrator` role documents. Customer and artisan may coexist; administrator is exclusive.
- Customers select a single artisan. Matching and AI do not assign an artisan.
- AI is optional and advisory. Deterministic eligibility remains the authority for selection.
- Artisans must be verified to receive work.
- Pricing is quotation-based in XAF. Do not add hourly-rate UI or backend fields.
- Payment release, payout, reviews, and disputes remain state-controlled and auditable.
- Do not introduce standalone material, wallet, escrow, or AI domain entities without changing the approved specification.

## 3. Backend: Entry Points and Cross-Cutting Behaviour

| Concern | Read first | Purpose |
|---|---|---|
| Application composition | `servicehub/bootstrap/app.php` | API routing, JSON exception response format, correlation IDs, `role`, `permission`, `account.active`, and `verified` middleware aliases. |
| API surface | `servicehub/routes/api.php` | Current route and middleware map. Never rely only on generated route dumps. |
| Scheduler | `servicehub/routes/console.php` | Dispute-resolution expiry, password-reset cleanup, and pending artisan-response expiry schedules. |
| Environment configuration | `servicehub/.env.example`, `servicehub/config/database.php` | Required local configuration. Use MongoDB values in the real `.env`; `.env.example` contains legacy Laravel defaults that must not be mistaken for current datastore intent. |
| Error contract | `servicehub/bootstrap/app.php`, `servicehub/app/Http/Requests/` | API errors return standard Laravel `message`/`errors` plus an `error` object and correlation/request identifier. |
| Dependencies | `servicehub/composer.json` | PHP 8.3+, Laravel 13, Sanctum, MongoDB Laravel integration, Laravel AI. |

### Backend domain files

| Domain | Key models | Main services/controllers |
|---|---|---|
| Identity and roles | `User`, `Customer`, `Artisan`, `Administrator` | `AuthService`, `UserRoleService`, `AuthController`, `UserRoleController`, `ProfileController` |
| Catalog and discovery | `ServiceCategory`, `Service`, `Artisan` | `CatalogService`, `ArtisanMatchingService`, `CatalogController`, `ArtisanDiscoveryController`, `ArtisanServiceOfferingController` |
| Requests | `ServiceRequest`, `ServiceRequestStatus` | `ServiceRequestLifecycleService`, `ServiceRequestService`, `ServiceRequestTrackingService`, `ServiceRequestController`, `ArtisanRequestController` |
| Payments and payout | `Payment`, `Payout`, status enums | `PaymentService`, `CamPayHttpGateway`, `SimulatedCamPayGateway`, `PaymentController`, `CamPayWebhookController` |
| Communication | `Conversation`, `Message` | `ConversationService`, `ConversationController`, `CustomerConversationController` |
| Trust and moderation | `Review`, `Dispute`, `AuditLog`, `PlatformNotification` | `ReviewService`, `DisputeService`, `DisputeResolutionService`, `AuditLogService`, `PlatformNotificationService` |
| Administration | platform settings and reports | `AdminReportingService`, `AdminUserManagementService`, admin controllers |
| AI | embedded `ServiceRequest.recommendation` only | `AiOrchestrationService`, `ArtisanRankingService`, agents under `app/Ai/Agents/` |

### Persistence and migrations

MongoDB is the active application datastore. Core migrations are in `servicehub/database/migrations/`:

- `0001_01_01_000000_create_users_table.php` — users, password-reset collection, partial unique phone index.
- `2026_09_09_000005_create_service_requests_collection.php` and `2026_09_29_000000_add_service_request_selection_lifecycle_indexes.php` — request indexes and selection lifecycle access paths.
- `2026_09_10_*` — payments/payouts and relationships.
- `2026_09_12_*` — reviews, disputes, conversations, messages, settings, audit logs, notifications, and resolution references.
- `2026_09_23_000000_create_separate_user_role_collections.php` — linked `customers`, `artisans`, and `administrators` collections.

Do not edit an already-applied migration for a deployed database. Add a new forward migration. Keep migrations MongoDB-native.

## 4. Service Request Lifecycle

### Primary states

```text
created
→ awaiting_artisan_selection | no_artisan_available
→ pending_artisan_response
→ artisan_approved
→ optional inspection_scheduled → inspection_completed
→ quotation_pending → quotation_received
→ payment_pending → booked → in_progress
→ awaiting_confirmation → completed
```

Controlled paths: cancellation before quotation acceptance, artisan/customer selection changes while awaiting response, timeout back to selection, and dispute interruption.

### Critical implementation files

| File | Responsibility |
|---|---|
| `app/Enums/ServiceRequestStatus.php` | Wire values. Preserve all existing states, including legacy `artisan_selected`. |
| `app/Models/ServiceRequest.php` | MongoDB fillable fields, casts, relations, attachment metadata. |
| `app/Services/Artisan/ArtisanMatchingService.php` | Deterministic verified/active/service/location/availability eligibility. No AI calls. |
| `app/Services/ServiceRequest/ServiceRequestLifecycleService.php` | Submission, matching recovery, selection, approve/decline/change, timeout, customer update, cancellation, history logging. |
| `app/Services/ServiceRequestService.php` | Quotations, inspections, materials, booking, work start, and completion transitions. |
| `app/Services/ServiceRequest/ServiceRequestTrackingService.php` | Normalized customer tracking payload, permissible actions, safe artisan projection, timeline, response expiry. |
| `app/Http/Controllers/Api/ServiceRequestController.php` | Customer request endpoints and media authorization. |
| `app/Console/Commands/ExpireArtisanResponses.php` | Applies response timeout through lifecycle service. |

### Tracking API

`GET /api/customer/service-requests/{serviceRequest}/tracking` is the preferred contract for a tracking UI. It returns safe request/artisan data, timeline, action permissions, and server-calculated pending response expiry. Do not calculate timeout or infer authorization rules solely in Flutter.

Related controlled endpoints:

```text
PATCH /customer/service-requests/{id}                 # update before selection/no-match only
POST  /customer/service-requests/{id}/cancel          # cancellation before quotation acceptance
POST  /customer/service-requests/{id}/select-artisan
POST  /customer/service-requests/{id}/change-artisan
POST  /customer/service-requests/{id}/retry-matching
POST  /customer/service-requests/{id}/quotation/accept
POST  /customer/service-requests/{id}/payments
POST  /customer/service-requests/{id}/completion/confirm
```

## 5. Frontend: Architecture and Entry Points

Flutter is feature-first MVVM with Riverpod:

```text
domain/models + domain/enums       immutable wire/domain representations
data/repositories                  authenticated API interaction and mapping
presentation/providers             Riverpod state / view models
presentation/pages + widgets       rendering and user interaction
ui/core                            router and shared visual tokens
```

| Concern | Files |
|---|---|
| App startup | `servicehub_frontend/lib/main.dart` |
| Auth/session state | `features/auth/presentation/providers/auth_providers.dart`, `features/auth/data/repositories/auth_repository.dart` |
| Router | `ui/core/router/app_router.dart`, `ui/core/router/auth_redirect.dart` |
| HTTP and tokens | `core/api/api_service.dart`, `core/api/token_storage.dart`, `core/constants/api_constants.dart` |
| Theme | `ui/core/theme/` and `core/theme/app_theme.dart` |
| Localization | `l10n/app_en.arb`, `l10n/app_fr.arb`, `core/localization/` |
| Brand | `assets/brand/logo_primary.svg`, `logo_light_bg.png`, and related assets |

### Active feature modules

- `features/customer/` — request wizard, discovery, selection, public profiles, customer shell/tabs, requests, conversations, payments, reviews, disputes, and tracking views.
- `features/artisan/` — artisan shell/tabs, selected requests, approve/decline, quotation, materials, inspection, completion, earnings, profile/offering management, and verification.
- `features/admin/` — reporting, users, catalogue, verification queue/detail, dispute queue/detail.
- `features/auth/`, `features/landing/`, and `features/splash/` — access and entry flows.

### Tracking implementation: important consolidation item

The active route screen is:

```text
features/customer/presentation/pages/request_tracking_page.dart
features/customer/presentation/providers/request_tracking_providers.dart
features/customer/data/repositories/service_request_repository.dart
```

It currently reads the general `GET /customer/service-requests/{id}` response and selects a dedicated status view in `presentation/widgets/tracking/`.

There is also a newer, currently unreferenced tracking-contract layer:

```text
domain/models/service_request_tracking.dart
data/repositories/service_request_tracking_repository.dart
presentation/providers/service_request_tracking_providers.dart
```

That layer consumes `GET /customer/service-requests/{id}/tracking`. Before extending tracking, consolidate on one approach. The recommended direction is to migrate the active status views to the normalized tracking API, then remove the unused duplicate layer.

### Tracking widgets

The folder `features/customer/presentation/widgets/tracking/` contains the status-specific visual implementation:

```text
awaiting_artisan_selection_view.dart   pending_artisan_response_view.dart
artisan_accepted_view.dart             quotation_received_view.dart
payment_pending_view.dart              booked_view.dart
in_progress_view.dart                  awaiting_confirmation_view.dart
completed_view.dart                    cancelled_view.dart
disputed_view.dart                     no_artisan_available_view.dart
```

Shared UI belongs in `tracking_app_bar.dart`, `tracking_timeline.dart`, `tracking_actions.dart`, `request_glance_card.dart`, and `request_details_card.dart`.

## 6. API Integration Rules

- Use `ApiService` for all backend calls. It supplies Bearer tokens, JSON headers, timeout handling, and normalized `ApiException` parsing.
- Never put payment, CamPay, Gemini, or Google server secrets in Flutter.
- Treat `404` on artisan-selected request endpoints as intentional non-enumeration behaviour, not a generic authorization bug.
- IDs are MongoDB IDs serialized as strings.
- Use wire enum values such as `pending_artisan_response`, never PHP enum case names.
- Use GeoJSON coordinates in `[longitude, latitude]` order.
- Customer UI must not present AI recommendations as assignments.
- Use quotation totals and XAF. Do not render hourly rates.

## 7. Current Known Follow-Up Work

1. **Consolidate tracking contracts** as described above.
2. **Replace remaining placeholders:** map/location visual fallback and mock coordinates in the request wizard; camera/gallery picker handlers; account settings UI.
3. **Normalize encoding:** some source comments/strings contain mojibake such as `â€“`; correct affected UTF-8 text before localization polishing.
4. **Refresh generated references** after API changes: `BACKEND_CONTRACT.md`, `servicehub/api_routes.txt`, and `servicehub/tracking_backend_dump.txt` are snapshots, not sources of truth.
5. **Integration test the full journey:** customer creates request → selects artisan → artisan approves → quotation → CamPay verification → booked → work → completion → payout/review/dispute paths.

## 8. Development and Verification

Do not run destructive database commands against a database with data you need.

```powershell
# Laravel
cd servicehub
php artisan migrate
php artisan test

# Flutter
cd ..\servicehub_frontend
flutter pub get
flutter analyze
flutter test
flutter run
```

For scheduled state changes, run a scheduler process during development:

```powershell
cd servicehub
php artisan schedule:work
```

## 9. Existing References and Their Authority

| File | Use | Authority |
|---|---|---|
| `SERVICEHUB_FINAL_IMPLEMENTATION_GUIDE_ENHANCED.md` | Product/business/architecture context | Living reference; revise deliberately |
| `servicehub/routes/api.php` | Endpoint registration | Current source evidence |
| `servicehub/app/**` | Behaviour and security | Current source evidence |
| `servicehub_frontend/lib/**` | Client behaviour | Current source evidence |
| `BACKEND_CONTRACT.md` | Fast integration reference | Derived; update after API changes |
| `servicehub/api_routes.txt` | Grouped API route snapshot | Derived on 2026-10-02; refresh after route work |
| `servicehub/tracking_backend_dump.txt` | Tracking source map | Derived on 2026-10-02; refresh after lifecycle/tracking work |
| `stitch_servicehub/` | Visual inspiration/export | Reference only; do not directly ship its generated HTML |

## 10. Safe Continuation Checklist

Before each module change:

1. Read the implementation guide section and current routes/services/models.
2. Identify the existing feature repository, provider/view model, page, and tests.
3. Preserve lifecycle authorization, history/audit logging, and secure file/payment practices.
4. Keep AI optional and advisory.
5. Implement the smallest coherent backend change before Flutter wiring where a contract is missing.
6. Add or update backend tests for business-rule changes and run Flutter analysis/tests before handoff.
7. Update this handoff, `BACKEND_CONTRACT.md`, and the implementation decision register when the architecture or API changes materially.
