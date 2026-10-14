# ServiceHUB Backend Contract

Refreshed from the Laravel source at `servicehub/` on 2026-10-02. This is a living, code-derived integration reference; `routes/api.php`, request validators, controllers, and services remain the current implementation evidence when they differ.

## 1. Stack

- Laravel: `13.31.0` (`composer.json` permits `^13.8`).
- PHP: `8.5.4` in the local application environment (`composer.json` requires `^8.3`).
- Database: MongoDB through `mongodb/laravel-mongodb ^5.8`; all application models use MongoDB Eloquent models unless otherwise stated.
- Authentication: `laravel/sanctum ^4.0`, personal access tokens persisted by `App\Models\PersonalAccessToken` on MongoDB.
- AI: `laravel/ai` is installed. AI endpoints exist, but AI is advisory only; manual matching remains authoritative.
- CamPay: HTTP integration is implemented for collection, webhook handling, payout/release, reconciliation, and idempotency-ledger workflows. It is not evidence of a production CamPay configuration.
- Google Maps: geocoding service is implemented; a request may provide a GeoJSON pin instead of an address. Configuration determines whether address geocoding succeeds.
- Mail driver: configured only through `MAIL_*` environment values; the effective driver cannot be safely inferred from source alone.

Notes for frontend: send a coordinate pin whenever possible; address-only creation depends on server-side geocoding configuration.

## 2. Models

All primary IDs serialize as MongoDB string IDs. Collections default to the plural model name unless `$table` is stated.

| Model / file | Collection | Fillable | Hidden | Casts / defaults / API-relevant methods |
|---|---|---|---|---|
| `User` `app/Models/User.php` | `users` | `name, first_name, last_name, email, phone, password, account_status, status, roles, active_role` | `password, remember_token, profile_photo` | casts: `email_verified_at: datetime`, `password: hashed`, `account_status: AccountStatus`; defaults: account/status=`active`, roles=`[]`; relations `customer()`, `artisan()`, `administrator()` has-one by `user_id`; deprecated `artisanProfile()`; methods `assignRole`, `syncRoles`, `hasRole`, `hasPermission`; status mutators keep `status` and `account_status` synchronized; name mutator derives first/last names if absent. |
| `Customer` `app/Models/Customer.php` | `customers` | `user_id, preferences, favorite_artisans, address_book, total_spent, total_requests, completed_requests` | none | defaults arrays empty and totals `0`; `user()` belongs-to `User` by `user_id`. |
| `Artisan` `app/Models/Artisan.php` | `artisans` (`$table`) | `user_id, professional_description, professional_title, bio, experience_years, certifications, languages, service_areas, service_location, availability, location, offered_services, service_offerings, verification_status, verification_documents, verification_history, rejection_reason, reviewed_at, payout_account, payout_phone, rating_average, review_count, completed_jobs, response_rate, cancellation_rate` | `payout_phone, payout_account, verification_documents` | casts `verification_status: VerificationStatus`, `reviewed_at: datetime`; arrays/stats default as source; `user()` belongs-to; `isProfileComplete()` requires description/bio/title plus experience; `setServiceLocationAttribute()` mirrors into `location`. |
| `ArtisanProfile` `app/Models/ArtisanProfile.php` | `artisans` | inherited | inherited | Compatibility alias of `Artisan`; new code uses `Artisan`. |
| `ServiceRequest` `app/Models/ServiceRequest.php` | `service_requests` | `customer_id, service_id, description, location, images, formatted_address, preferred_schedule, status, selected_artisan_id, payment_id, status_history, inspection, quotation, materials, completion, recommendation, pending_since, no_artisan_reason, matching_attempts, selection_history, ai_assist_enabled, urgency` | `images` | appends `image_attachments`; casts `status: ServiceRequestStatus`, `pending_since: datetime`, `matching_attempts: integer`, `ai_assist_enabled: boolean`, `urgency: UrgencyLevel`; defaults attempts `0`, selection history `[]`, AI assist false; belongs-to `customer`, `service`, `selectedArtisan`; accessor returns safe image metadata only. |
| `Service` `app/Models/Service.php` | `services` | `service_category_id, name, slug, description, is_active` | none | `is_active: boolean`; `category()` belongs-to `ServiceCategory` via `service_category_id`. |
| `ServiceCategory` `app/Models/ServiceCategory.php` | `name, slug, description, icon, is_active` | none | `is_active: boolean`; `services()` has-many `Service`. |
| `Payment` `app/Models/Payment.php` | `payments` | `service_request_id, customer_id, amount, currency, status, provider, provider_reference, idempotency_key, external_reference, phone, events, ai_anomaly, commission_rate_snapshot, commission_amount, artisan_gross_amount, artisan_net_amount` | `phone, events` | `status: PaymentStatus`; monetary snapshots are `float`. |
| `Payout` `app/Models/Payout.php` | `payouts` | `payment_id, service_request_id, artisan_profile_id, amount, currency, status, provider, provider_reference, external_reference, events, gross_amount, commission_amount` | `events` | `status: PayoutStatus`. |
| `Conversation` `app/Models/Conversation.php` | `conversations` | `service_request_id, customer_id, artisan_profile_id` | none | no casts/defaults/relations declared. |
| `Message` `app/Models/Message.php` | `messages` | `conversation_id, sender_id, body, attachments` | none | no casts/defaults declared. |
| `Review` `app/Models/Review.php` | `reviews` | `service_request_id, customer_id, artisan_profile_id, rating, comment, created_at, updated_at` | none | `rating: integer`. |
| `Dispute` `app/Models/Dispute.php` | `disputes` | `service_request_id, payment_id, reporter_id, reporter_role, reason, description, evidence, updates, status, prior_request_status, status_history, resolution, pending_resolution, resolution_reference` | none | `status: DisputeStatus`. |
| `PlatformSetting` `app/Models/PlatformSetting.php` | `platform_settings` | `key, value, description, updated_by` | none | `value: float`. |
| `Administrator` `app/Models/Administrator.php` | `administrators` | `user_id, role_level, permissions` | none | defaults `role_level: administrator`, `permissions: []`; `user()` belongs-to `User`. |
| `AuditLog` `app/Models/AuditLog.php` | `audit_logs` | `event_type, actor_id, subject_type, subject_id, metadata, expires_at` | none | `expires_at: datetime`; updating/deleting throws `LogicException` (immutable). |
| `PlatformNotification` `app/Models/PlatformNotification.php` | `platform_notifications` | `recipient_id, type, title, body, payload, read_at` | none | `read_at: datetime`. |
| `ResolutionReference` `app/Models/ResolutionReference.php` | `resolution_references` | `reference, dispute_id, status` | none | Durable global idempotency ledger; no casts. |
| `PersonalAccessToken` `app/Models/PersonalAccessToken.php` | `personal_access_tokens` | inherited Sanctum fields | inherited | MongoDB Sanctum model, string key type. |

Notes for frontend: hidden fields are deliberately absent from ordinary serialized responses; never rely on them being returned.

## 3. Enums

| Enum / file | Cases |
|---|---|
| `AccountStatus` `app/Enums/AccountStatus.php` | `ACTIVE=active`, `SUSPENDED=suspended` |
| `VerificationStatus` `app/Enums/VerificationStatus.php` | `UNVERIFIED=unverified`, `PENDING=pending`, `VERIFIED=verified`, `REJECTED=rejected`, `SUSPENDED=suspended` |
| `ServiceRequestStatus` `app/Enums/ServiceRequestStatus.php` | `CREATED=created`, `AWAITING_ARTISAN_SELECTION=awaiting_artisan_selection`, `PENDING_ARTISAN_RESPONSE=pending_artisan_response`, `ARTISAN_APPROVED=artisan_approved`, `ARTISAN_SELECTED=artisan_selected`, `NO_ARTISAN_AVAILABLE=no_artisan_available`, `INSPECTION_SCHEDULED=inspection_scheduled`, `INSPECTION_COMPLETED=inspection_completed`, `QUOTATION_PENDING=quotation_pending`, `QUOTATION_RECEIVED=quotation_received`, `QUOTATION_ACCEPTED=quotation_accepted`, `PAYMENT_PENDING=payment_pending`, `BOOKED=booked`, `IN_PROGRESS=in_progress`, `AWAITING_CONFIRMATION=awaiting_confirmation`, `COMPLETED=completed`, `CANCELLED=cancelled`, `DISPUTED=disputed` |
| `PaymentStatus` `app/Enums/PaymentStatus.php` | `INITIATED=initiated`, `PROCESSING=processing`, `HELD=held`, `FAILED=failed`, `CANCELLED=cancelled`, `RELEASING=releasing`, `RELEASED=released`, `REFUNDING=refunding`, `REFUNDED=refunded`, `PARTIALLY_REFUNDED=partially_refunded`, `REFUND_PENDING_MANUAL=refund_pending_manual`, `RECONCILIATION_REQUIRED=reconciliation_required`, `DISPUTED=disputed`, `UNDER_REVIEW=under_review` |
| `PayoutStatus` `app/Enums/PayoutStatus.php` | `INITIATED=initiated`, `PROCESSING=processing`, `PAID=paid`, `FAILED=failed` |
| `DisputeStatus` `app/Enums/DisputeStatus.php` | `OPENED=opened`, `UNDER_REVIEW=under_review`, `AWAITING_INFORMATION=awaiting_information`, `PENDING_EXECUTION=pending_execution`, `UNDER_INVESTIGATION=under_investigation`, `RESOLVED_WITH_MANUAL_REFUND_PENDING=resolved_with_manual_refund_pending`, `RECONCILIATION_REQUIRED=reconciliation_required`, `RESOLVED=resolved`, `CLOSED=closed` |
| `UrgencyLevel` `app/Enums/UrgencyLevel.php` | `Low=low`, `Medium=medium`, `High=high` |
| `CategoryStatus` | Not found. |

No enum currently declares helper methods.

Notes for frontend: use string values on the wire, never PHP case names.

## 4. Embedded Document Shapes

The following shapes are code-observed. Keys that a service writes conditionally are marked optional.

```json
{
  "profile_photo": {"path":"profile-photos/{userId}/{uuid}.jpg","mime_type":"image/jpeg","size":12345},
  "location": {"type":"Point","coordinates":[9.7679,4.0511],"label":"Douala V"},
  "preferred_schedule": {"date":"2026-10-01","window":"Morning","notes":"optional"},
  "inspection": {"scheduled_at":"ISO-8601","call_out_fee":5000,"notes":"optional","status":"scheduled|completed","findings":"optional","completed_at":"ISO-8601"},
  "quotation": {"labor_amount":15000,"currency":"XAF","scope":"text","valid_until":"ISO-8601","status":"received|accepted|rejected","submitted_at":"ISO-8601","submitted_by":"userId","accepted_at":"ISO-8601","rejected_at":"ISO-8601","rejection_reason":"optional"},
  "material": {"name":"PVC pipe","quantity":2,"unit_cost":1500,"estimated_cost":3000,"proposal_version":1,"approval_status":"proposed|approved","approved_at":"optional ISO-8601"},
  "completion": {"started_at":"ISO-8601","status":"awaiting_customer_confirmation|confirmed","reported_at":"ISO-8601","reported_by":"userId","confirmed_at":"ISO-8601","confirmed_by":"userId","notes":"optional"},
  "status_history_item": {"status":"service-request-status","occurred_at":"ISO-8601","actor_id":"userId|null","event":"optional string","artisan_id":"optional artisanId","reason":"optional"},
  "selection_history_item": {"event":"selected|declined|timeout|changed_by_customer","artisan_id":"artisanId","artisan_name":"string|null","occurred_at":"ISO-8601","reason":"string|null"},
  "service_offering": {"service_reference":"serviceId","is_active":true,"offering_id":"optional legacy id"},
  "availability": {"accepting_requests":true,"radius_km":25,"service_radius_km":"optional numeric","booked_dates":["YYYY-MM-DD"],"monday":[{"start":"08:00","end":"18:00"}]},
  "verification_history_item": {"status":"verification-status","reviewed_at":"ISO-8601","reason":"optional"},
  "attachment": {"id":"uuid","path":"private path","name":"file.jpg","mime_type":"image/jpeg","size":12345},
  "dispute_evidence_item": {"id":"uuid","path":"private path","name":"file.jpg","mime_type":"image/jpeg","size":12345}
}
```

- `Artisan.service_areas`, `certifications`, `languages`, `offered_services`, `service_offerings`, `verification_documents`, `verification_history`, and `ServiceRequest.materials`, `selection_history`, `status_history`, `images` are arrays. Defaults are documented in model defaults; most nested objects have no schema cast.
- `Artisan.location` and `service_location` are GeoJSON points. The mutator mirrors `service_location` to `location`.
- `Payment.events`, `Payout.events`, `Payment.ai_anomaly`, `Dispute.updates/resolution/pending_resolution`, `Conversation` participants, and `ServiceRequest.recommendation` are not structurally validated by their models. `Conversation` uses top-level `customer_id` and `artisan_profile_id`, not a `participants` array.
- `images` are hidden and serialize only as `image_attachments` (`id,name,mime_type,size`).

Notes for frontend: `preferred_schedule` is an object, not an array; raw attachment paths are private and must be downloaded from the authorized endpoint.

## 5. API Endpoints

All API routes include Laravel's `api` middleware. Authenticated routes require `Authorization: Bearer <Sanctum token>` and apply `account.active`; role routes also apply `role:customer` or `role:artisan`. Permission-based admin routes are listed with their exact permission middleware. Route IDs are MongoDB IDs.

### Shared request validation

Exact FormRequest rules used by the most common endpoints:

| Endpoint action | Fields and exact rules |
|---|---|
| customer service request store | `service_id: required|string`; `description: required|string|min:10|max:5000`; `ai_assist_enabled: sometimes|boolean`; `address: nullable|string|min:3|max:500|required_without:location`; `location: nullable|array:label,type,coordinates|required_without:address`; `location.label: required_with:location|string|max:255`; `location.type: required_with:location|in:Point`; `location.coordinates: required_with:location|array|size:2`; coordinate 0 `required_with:location|numeric|between:-180,180`; coordinate 1 `required_with:location|numeric|between:-90,90`; `images: nullable|array|max:5`; each image `file|image|mimetypes:image/jpeg,image/png,image/webp|dimensions:max_width=4096,max_height=4096|max:5120`; `preferred_schedule: nullable|array:date,window,notes`; date `nullable|date|after_or_equal:today`; window `nullable|string|max:100`; notes `nullable|string|max:500`. |
| select artisan | `artisan_profile_id: required|string` |
| change/decline artisan request | `reason: nullable|string|max:500` |
| schedule inspection | `scheduled_at: required|date|after:now`; `call_out_fee: nullable|numeric|min:0`; `notes: nullable|string|max:1000` |
| quotation | `labor_amount: required|numeric|min:0`; `currency: required|string|size:3`; `scope: required|string|min:10|max:5000`; `valid_until: required|date|after:now` |
| reject quotation | `reason: required|string|min:5|max:1000` |
| materials proposal | `materials: required|array|min:1|max:100`; item `name: required|string|max:255`, `quantity: required|numeric|gt:0`, `unit_cost: required|numeric|min:0` |
| approve materials | `approved_total: required|numeric|min:0` |
| completion report | `notes: nullable|string|max:2000` |
| review | `rating: required|integer|min:1|max:5`; `comment: nullable|string|max:2000` |

### Public

| Method/path | Auth / middleware | Success shape / notes |
|---|---|---|
| `GET /api/service-categories` | none | `{"service_categories":[{"id":"...","name":"Plumbing","slug":"plumbing","description":"...","icon":null,"is_active":true}]}` |
| `GET /api/services` | none | `{"services":[{"id":"...","service_category_id":"...","name":"Plumbing","slug":"plumbing","description":"...","is_active":true}]}` |
| `GET /api/artisans` | none | discovery list; query parameters are controller-defined; only public artisan fields are returned. |
| `POST /api/auth/register/customer` | `throttle:auth` | creates customer and returns user/token payload; validation is `CustomerRegistrationRequest`. |
| `POST /api/auth/register/artisan` | `throttle:auth` | creates user/artisan registration payload; validation is `ArtisanRegistrationRequest`. |
| `POST /api/auth/login` | `throttle:auth` | `{"token":"sanctum-token","user":{...}}`; validation `LoginRequest`. |
| `POST /api/auth/forgot-password` | `throttle:auth` | deliberately generic success response; validation `ForgotPasswordRequest`. |
| `POST /api/auth/reset-password` | `throttle:auth` | password-reset response; validation `ResetPasswordRequest`. |

### Authenticated (any active user)

| Method/path | Middleware | Success shape / notes |
|---|---|---|
| `GET /api/user`, `GET /api/auth/me` | `auth:sanctum, account.active` (`auth/me` also `throttle:auth`) | authenticated user object. |
| `POST /api/auth/logout` | auth + active + `throttle:auth` | revokes current token. |
| `PUT /api/auth/password` | auth + active + `throttle:auth` | password update; `ChangePasswordRequest`. |
| `GET /api/user/roles` | auth + active | `{"roles":["customer","artisan"],"active_role":"customer"}`. |
| `POST /api/user/switch-role` | auth + active | `SwitchRoleRequest`; response includes `active_role`. |
| `POST /api/user/become-artisan` | auth + active | `BecomeArtisanRequest`; adds artisan role/profile, customer role remains. |
| `GET /api/user/notifications` | auth + active | paginated notifications. |
| `PATCH /api/user/notifications/{notification}/read` | auth + active | marks only recipient-owned notification read. |
| `GET /api/users/{user}/photo` | auth + active | authorized private-photo download. |
| `GET /api/email/verify`, `GET /api/email/verify/{id}/{hash}`, `POST /api/email/verification-notification` | auth + active; signed/throttled where routed | email verification status, signed verification, resend (throttle `6,1`). |

### Authenticated (customer)

| Method/path | Success response / state requirement |
|---|---|
| `GET /api/customer/profile` | `{"profile":{"name":"Jean Mbarga","email":"j@example.cm","phone":"...","profile_photo":null,"customer":{...},"customer_profile":{"default_location":null,"preferences":[]}}}` |
| `PATCH /api/customer/profile`, `POST/GET/DELETE /api/customer/profile/photo` | profile update/photo upload/private download/delete; validators `UpdateCustomerProfileRequest`, `StoreProfilePhotoRequest`. |
| `GET /api/customer/service-requests` | `{"service_requests":[ServiceRequest...]}`; customer-owned only. |
| `POST /api/customer/service-requests` | 201 `{"service_request":{"id":"...","status":"awaiting_artisan_selection","ai_assist_enabled":true,"location":{"type":"Point","coordinates":[9.7679,4.0511],"label":"Douala V"},"image_attachments":[]}}`. |
| `GET /api/customer/service-requests/{id}` and image download | customer-owned only. |
| `GET /api/customer/service-requests/{id}/tracking` | Customer-owned normalized tracking payload: safe request and selected-artisan details, sanitized timeline, server-calculated `pending_response.expires_at`, `next_action`, and lifecycle permissions. |
| `PATCH /api/customer/service-requests/{id}` | Updates description, location/address, or preferred schedule only while awaiting artisan selection or recovering from no availability. Every update re-runs deterministic matching and records history. |
| `POST /api/customer/service-requests/{id}/cancel` | Customer cancellation with a required reason, permitted only through quotation receipt. Requests at quotation acceptance or later require the payment support/dispute process. |
| `GET /api/customer/service-requests/{id}/eligible-artisans` | `{"artisans":[{"id":"...","professional_title":"Plumber","bio":"...","experience_years":8,"service_areas":["Douala V"],"availability":{"accepting_requests":true},"rating_average":4.8,"review_count":42}]}`. |
| `POST .../select-artisan` | changes to `pending_artisan_response`; explicit selection only. |
| `POST .../change-artisan`, `POST .../retry-matching` | customer-owned; change only while pending; retry only no-artisan state. |
| `POST .../inspection`, quotation accept/reject, materials approve, completion confirm, payout retry | lifecycle-gated, response key is `service_request`; completion also returns `payout`. |
| `POST .../payments`, `POST /api/customer/payments/{payment}/reconcile` | verified email plus `throttle:payments`; payment initiate uses `InitiatePaymentRequest`. |
| request conversation/messages/attachment routes | only conversation participants; message uses `StoreMessageRequest`. |
| disputes, evidence, reviews | ownership/lifecycle restricted; validators `OpenDisputeRequest`, `AddDisputeEvidenceRequest`, `StoreReviewRequest`. |

### Authenticated (artisan)

| Method/path | Success response / state requirement |
|---|---|
| `GET/PATCH /api/artisan/profile` | profile and `UpdateArtisanProfileRequest`; PATCH requires verified email. |
| `GET/POST/PATCH/DELETE /api/artisan/service-offerings[/{offeringId}]` | embedded offering CRUD; validators `StoreServiceOfferingRequest`, `UpdateServiceOfferingRequest`. |
| `POST /api/artisan/service-requests/{id}/approve` | `{"service_request":{"status":"artisan_approved",...}}`; selected artisan only. |
| `POST .../decline` | returns request to selection; selected artisan only. |
| inspection complete, quotation, materials, start, completion | selected artisan only; state-gated; return `{"service_request":{...}}`. |
| request image/conversation/messages/attachment | selected artisan or participant only; unauthorized request selection returns 404, not 403. |
| disputes/evidence | artisan ownership/lifecycle checks. |

### Authenticated (admin)

All routes require `auth:sanctum, account.active` plus the listed permission middleware.

| Method/path | Permission |
|---|---|
| `GET /api/admin/artisans/pending`; `POST /api/admin/artisans/{artisan}/approve|reject` | `view-artisan-applications`, `approve-artisan`, `reject-artisan` (approve/reject also `throttle:verification`) |
| `GET /api/admin/users`; `PATCH /api/admin/users/{user}/status` | `manage-users` |
| CRUD `/api/admin/service-categories` and `/api/admin/services` (no show) | `manage-services` |
| dashboard, payments, payouts, audit logs | `manage-reports` |
| all `/api/admin/disputes` index/show/review/awaiting-information/investigate/resolve/confirm-resolution/cancel-resolution/reconcile | `manage-disputes` |
| `GET|PUT /api/admin/settings/commission` | `manage-platform-settings` |

### AI and webhooks

| Method/path | Auth / middleware | Notes |
|---|---|---|
| `POST /api/ai/recommend` | customer, active, `throttle:ai` | advisory recommendations only. |
| `POST /api/ai/service-requests/{id}/understand` | customer, active, `throttle:ai` | analyzes a customer-owned request; no automatic artisan assignment. |
| `POST /api/webhooks/campay` | public `api` | provider webhook; signature/transition checks are implemented in the webhook/payment services. |

Typical errors: `401` unauthenticated, `403` wrong role/permission/inactive account, `404` missing or non-owned resource, `422` FormRequest/lifecycle validation, `429` throttle. Payment-related operations support server-side idempotency via payment/resolution references; ordinary endpoints do not accept a documented generic idempotency header.

Notes for frontend: state transitions are authoritative; never optimistically advance a request beyond the returned `status`.

## 6. Storage Layout

All inspected uploads use the `local` disk and private paths. Downloads are streamed by authorized API endpoints; no public URL is returned.

| Content | Path convention | Access |
|---|---|---|
| Profile photo | `profile-photos/{userId}/{uuid}.{extension}` | owner metadata is hidden; authenticated photo download endpoint. |
| Service-request image | `service-requests/{requestId}/{uuid}.{extension}` | customer owner or selected artisan via distinct download endpoints. |
| Message attachment | private service-managed path under conversation attachment storage | conversation participant only. |
| Verification document | Not found as a standalone upload endpoint/path convention; model field exists and is hidden. |

Notes for frontend: render images/files by authenticated download request, not by concatenating a storage URL.

## 7. Authentication

- Login/registration issue Sanctum personal-access tokens. Send `Authorization: Bearer <token>`.
- No explicit token lifetime is set in the inspected application code.
- Logout deletes/revokes the current access token; password changes/reset revoke tokens through the auth service workflow.
- Password endpoints: `POST /api/auth/forgot-password` (generic non-enumerating response) and `POST /api/auth/reset-password`; use the exact FormRequest fields in `ForgotPasswordRequest` and `ResetPasswordRequest`.
- Account-active middleware blocks suspended accounts. Email verification is specifically required for payment initiation and artisan profile PATCH.

Notes for frontend: persist the token securely; re-authenticate after a password change/reset.

## 8. Error Format

Laravel validation responses use HTTP 422 and the framework shape:

```json
{"message":"The given data was invalid.","errors":{"field":["The field is required."]}}
```

Other controller/middleware failures may use Laravel's standard JSON `message` shape, e.g. `{"message":"Unauthenticated."}`. Correlation-ID support is installed (`bilfeldt/laravel-correlation-id`), but the exact `request_id` response-header name was not verified from middleware configuration.

| Status | Meaning |
|---|---|
| 401 | missing/invalid Sanctum token |
| 403 | role, permission, verification, or account-status denial |
| 404 | route binding failure or ownership concealment |
| 409 | documented email-already-verified closure response |
| 422 | validation or prohibited lifecycle transition |
| 429 | named rate limiter exceeded |

Notes for frontend: handle both `message` and `errors`; do not depend on an unverified `request_id` header.

## 9. Seeders and Sample Data

| Seeder | Creates |
|---|---|
| `DatabaseSeeder` | calls PlatformSettings, DevelopmentUser, ServiceCatalog, Artisan seeders. |
| `PlatformSettingsSeeder` | `artisan_response_timeout_hours=24`. |
| `DevelopmentUserSeeder` | `admin@servicehub.test`, `customer@servicehub.test`, `artisan@servicehub.test` with documented test passwords and role profiles. Development-only credentials must not ship to production. |
| `ServiceCatalogSeeder` | six active categories/services: plumbing, electrical, carpentry, painting, masonry, mechanics. |
| `ArtisanSeeder` | verified sample artisan users/profiles, active offerings, Douala GeoJSON location, ratings and schedules. |

| Factory | `definition()` / states |
|---|---|
| `UserFactory` | `name: fake()->name()`, unique safe email, `email_verified_at: now()`, hashed shared `password`, random `remember_token`; `unverified()` changes email verification to null. It deliberately omits optional `phone`. |
| `ServiceRequestFactory` | customer factory, `service_id: service-{uuid}`, faker sentence, `status: created`, `status_history: []`; no states. |

Notes for frontend: seeded artisan `service_areas` are objects (`city`, `radius_km`) while matching code also supports string areas; see caveats.

## 10. Live Collection Samples

Attempted read-only MongoDB sampling through the configured Laravel application for `users, artisans, service_requests, services, service_categories, payments, payouts, reviews, disputes, conversations, messages, platform_settings, audit_logs, platform_notifications`. The command emitted only a non-fatal PsySH history-write permission notice and no collection output. Representative live documents are therefore **unavailable** rather than fabricated.

Notes for frontend: use Sections 2 and 4 as the current source-derived contract reference, then verify against live controller responses when integration changes.

## 11. Known Gaps and Caveats

- `StoreServiceRequestRequest` validates optional `urgency` as `low`, `medium`, or `high`; do not introduce client-only urgency values.
- `ServiceRequestFactory` still creates legacy `created` requests, whereas new customer submission uses `awaiting_artisan_selection` or `no_artisan_available`.
- `ArtisanSeeder` stores `service_areas` as objects, while deterministic matching currently normalizes each area by string cast; coordinates/radius provide the dependable eligibility path for seeded profiles.
- `Artisan.offered_services` and `service_offerings` coexist. Matching reads `service_offerings`.
- `Conversation` has no `participants` embedded document despite that name sometimes being used conceptually; use top-level IDs.
- Artisan verification has a dedicated authenticated workflow, including identity data, identity document/selfie/supporting-document uploads, submit, delete, and private download routes.
- Payment/Payout `events` and several dispute/recommendation fields are untyped embedded data; frontend should render only fields explicitly returned by an endpoint.
- The exact global correlation/request-ID response header was not confirmed.
- `CategoryStatus` does not exist.

Notes for frontend: treat untyped nested data as opaque unless it is produced by a documented controller response.

## 12. Quick Reference Table

| Collection | Main embedded shapes | Primary readers | Primary writers |
|---|---|---|---|
| users | profile_photo, roles | auth, profiles, admin | auth, user role/profile/admin |
| customers | preferences, address_book | customer profile | customer profile/role service |
| artisans | offerings, availability, location, verification data | discovery, profiles, matching | role/profile/offering/admin verification |
| service_requests | location, schedules, quotations, materials, histories | customer/artisan request APIs | request lifecycle/services |
| services/service_categories | catalog fields | public catalog/admin | admin/seeders |
| payments/payouts | events/financial snapshots | customer/admin | payment/dispute services/webhook |
| conversations/messages | attachment arrays | participant endpoints | conversation service |
| reviews | none | discovery/review flows | review controller |
| disputes/resolution_references | evidence, resolution state | customer/artisan/admin | dispute service/admin |
| platform_settings | scalar value | lifecycle/admin | seeder/admin |
| audit_logs | metadata | admin reports | audit services |
| platform_notifications | payload | user notifications | notification services |

Notes for frontend: collection names are backend storage details; interact through the API paths above, not direct MongoDB access.
