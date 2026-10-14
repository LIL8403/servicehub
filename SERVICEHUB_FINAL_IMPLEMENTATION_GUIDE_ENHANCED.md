# ServiceHUB — Final Implementation Guide
## Secure Digital Service Marketplace for Connecting Clients with Verified Artisans in Cameroon

**Product:** ServiceHUB  
**Platforms:** Flutter Web + Flutter Mobile  
**Backend:** Laravel REST API  
**Database:** MongoDB  
**Payment Provider:** CamPay API  
**Maps/Location:** Google Maps Platform  
**Architecture:** 3-tier; Flutter presentation, Laravel application, MongoDB data  
**Development strategy:** Backend-first, then frontend, then integration and final QA

---

## 1. Project Overview

> **Current implementation-period rule:** Deployment architecture, production hosting, CI/CD, disaster-recovery infrastructure and production operations are specified in this guide for architectural completeness, but **they are not part of the current implementation period** unless explicitly brought into scope later. The current period focuses on local development, backend implementation, testing/stabilization, Flutter implementation and application integration.

ServiceHUB is a secure digital marketplace designed for the Cameroonian market. It connects customers who need services with verified artisans such as electricians, plumbers, carpenters, mechanics, painters and masons.

The platform centralizes service discovery, request submission, artisan selection, optional inspection, quotation, material approval, payment, service execution, completion confirmation, payout, reviews and dispute handling.

The system is designed around three priorities: **trust, transparency and secure transactions**. It also introduces optional AI-assisted decision support to help customers understand service requests and identify suitable artisans without removing the customer's control over artisan selection.

### 1.1 Problem Context

Service discovery in Cameroon frequently depends on personal recommendations, WhatsApp, Facebook and informal networks. Customers may have difficulty verifying an artisan's identity, experience and reliability, comparing alternatives, obtaining transparent quotations, coordinating appointments and ensuring that payment is handled safely.

Artisans also face limited digital visibility and may depend heavily on personal networks to find customers.

ServiceHUB provides a centralized marketplace where professional information, verification, service requests, communication, transactions and reputation can be managed through one platform.

### 1.2 Main Objectives

- Centralize discovery of service professionals.
- Provide meaningful artisan verification and professional profiles.
- Allow customers to describe service needs with text, images, location and preferred schedule.
- Allow customers to manually search/filter artisans or optionally use AI assistance.
- Allow customers to choose the artisan they want to hire.
- Support inspection, quotation and negotiation workflows.
- Manage job-specific materials transparently.
- Process payments through CamPay.
- Support controlled payment holding/release in the application workflow without falsely claiming that CamPay itself provides contractual escrow.
- Provide secure completion, payout, review and dispute workflows.
- Improve artisan visibility and reputation.
- Apply security, auditing, validation and professional software-engineering practices.

### 1.3 Target Users

**Customer:** Searches for services, creates requests, selects artisans, communicates, pays, confirms completion, reviews and reports issues.

**Artisan:** Maintains professional profile, submits verification information, defines services/service areas and availability, responds to requests, performs inspections, submits quotations, executes jobs and receives payouts.

**Administrator:** Manages users, artisan verification, service categories/services, disputes, reports and platform oversight.

---

## 2. Marketplace Concept and Lifecycle

### 2.1 Normal/manual discovery

```text
Create Service Request
→ Browse/Search/Filter Artisans
→ Review Profiles
→ Select Artisan
```

### 2.2 Optional AI-assisted discovery

```text
Create Service Request
→ Choose to use AI assistance
→ AI analyzes request
→ AI recommends/ranks suitable artisans
→ Customer reviews recommendations
→ Select Artisan
```

AI is optional and advisory. It must never silently assign an artisan. A failed, unavailable, timed-out or low-confidence AI operation must not block the normal marketplace workflow.

### 2.3 Common downstream lifecycle

```text
Artisan Selected
→ Optional Inspection
→ Quotation
→ Materials Approval
→ Payment
→ Booking
→ In Progress
→ Completion Confirmation
→ Payment Release / Payout
→ Review
→ Possible Dispute
```

The customer remains the decision-maker. AI recommendations, quotation analysis and security anomaly detection support decisions; they do not replace human decisions or administrator review.

---

## 3. Functional Requirements

### 3.1 Authentication and Account Management

- Customer, artisan and administrator accounts.
- Secure registration/login/logout.
- Password hashing and secure password change/reset.
- Email/phone verification where implemented.
- Account status management.
- Role-based access control.
- Token-based API authentication.

**Implemented identity decision (2026-09-23):** `User` is the authentication/account record and remains separate from role-specific documents. A non-administrator may hold both `customer` and `artisan` roles, with `active_role` recording the selected dashboard context. `Customer`, `Artisan` and `Administrator` are separate MongoDB collections linked by `user_id`; they are not embedded in `User`. A customer becoming an artisan always retains the customer role. Administrator accounts are exclusive and cannot convert to customer or artisan roles.

### 3.2 Customer Profile

Customers can maintain personal information, profile image, default location and preferences.

The active `customers` collection stores customer-specific preferences, favourites, address book and aggregate request/spending counters. It is distinct from `users` and from payment records, which retain the immutable `customer_id` user reference required for financial auditability.

Customer profile photos are stored on the private server-side filesystem, with JPEG/PNG/WebP, size and dimensions validation. API responses expose metadata only; authenticated customer-only download and replacement endpoints prevent direct file-path disclosure and unauthorized object access.

### 3.3 Artisan Profile and Verification

Artisans can maintain professional descriptions, experience, service offerings, service areas, availability and reputation information.

Verification must support submission, review, approval, rejection and suspension. Verification information and status must be auditable.

The active `artisans` collection stores the professional profile, service offerings, location/service areas, verification data, payout configuration and reputation/operational metrics. An artisan profile begins as `pending`; an artisan must be verified before being selected for a service request or receiving work.

### 3.4 Service Catalog

Administrators manage service categories and individual services. Requests reference a service.

### 3.5 Service Requests

A customer can create a request containing:

- Service.
- Problem/service description.
- Images.
- Location.
- Preferred date/time information.
- Optional AI recommendation data.
- Inspection information where required.
- Quotation information.
- Materials information.
- Completion information.

The request lifecycle must be state-controlled and auditable.

### 3.6 Artisan Discovery

Manual discovery must support relevant filters such as:

- Service/skill match.
- Location/service area.
- Availability.
- Verification status.
- Rating.
- Experience.
- Completed jobs.
- Response rate.
- Cancellation rate.

Location should help discovery but must not be the only selection criterion.

### 3.7 Inspection

Some services require an artisan to inspect the problem before producing a final quotation. An inspection may have a call-out fee.

The same customer must not be charged multiple inspection fees for the same applicable inspection unless a clearly justified business rule permits a new inspection.

### 3.8 Quotations

The artisan can submit a quotation after evaluating the request and/or inspection. The customer can accept or reject it. Negotiation is allowed where appropriate.

AI quotation analysis may highlight unusual prices or differences, but it must remain advisory and must not impose a price.

### 3.9 Materials

Ordinary tools and recurring supplies are the artisan's responsibility. Job-specific repair materials or parts are the customer's responsibility.

The artisan proposes required materials and estimated costs. The customer approves them. Approved material costs must be funded/authorized before the artisan is expected to purchase them. If the cost exceeds the approved amount, execution must pause until additional approval is obtained.

Materials remain embedded in `ServiceRequest`; no separate MaterialRequest domain class is required.

### 3.10 Payments

Payments are initiated through the Laravel backend and CamPay API. Flutter clients must never receive or store secret payment credentials.

The application must protect against duplicate payment confirmation, replay and inconsistent transaction states.

Payment states include initiation, processing, held, releasing, released, refunding, refunded and failed as appropriate.

For the academic prototype, `held` represents the application's controlled payment workflow. Do not describe this as a legally guaranteed escrow service unless the actual financial arrangement supports that claim.

### 3.11 Service Execution and Completion

After payment/booking conditions are satisfied, the artisan starts the service. The service moves through execution and completion confirmation.

Payment release should occur only after the defined completion conditions are satisfied. Disputes must be able to interrupt normal release handling according to the approved business rules.

### 3.12 Payout

Once release conditions are satisfied, the platform processes the artisan payout through the selected CamPay integration. Commission handling must be represented in the transaction/service logic without introducing unnecessary standalone domain classes.

### 3.13 Reviews

Customers can rate and review completed services. Reviews contribute to artisan reputation.

### 3.14 Disputes

Customers and artisans can report issues. Administrators investigate and resolve disputes. Relevant evidence and communications should be retained for audit purposes.

### 3.15 Communication

Each service request may initiate a conversation containing messages between participants. Messages can support text, images and documents where appropriate.

---

## 4. AI Architecture

AI is a supporting capability, not a mandatory dependency of the marketplace lifecycle. The normal/manual marketplace workflow must always remain available.

### 4.1 AI Service Layer

AI functionality is implemented in the Laravel application layer through dedicated application services. AI capabilities are not domain entities.

```text
Flutter
   ↓
Laravel REST API
   ↓
AI Orchestration / Application Service
   ↓
Configured AI Provider or Recommendation Engine
   ↓
Laravel
   ↓
MongoDB
```

The exact AI provider, SDK or model is an implementation decision and may be selected according to availability, cost, compatibility, data requirements and project constraints. It must not change the approved business workflow.

### 4.2 Request Understanding

The AI service may analyze the customer's description to identify:

- Likely service category/service.
- Problem type.
- Urgency.
- Useful contextual information.
- Missing or useful request information where practical.

AI output is advisory and must be validated before being used by the application.

### 4.3 Artisan Recommendation

The recommendation/ranking service may use available factors such as:

- Service/skill compatibility.
- Verification status.
- Location/distance.
- Availability.
- Rating.
- Completed jobs.
- Experience.
- Response rate.
- Cancellation rate.
- Customer preferences.

Recommendations should provide meaningful reasons where practical. Recommendations are suggestions, not assignments.

### 4.4 Quotation Analysis

AI may compare quotations or identify unusual pricing patterns using available marketplace information.

It must not automatically impose a final price, replace customer/artisan negotiation, or reject a quotation solely because an AI model considers it unusual.

### 4.5 Security Anomaly Detection

AI may flag suspicious transaction, cancellation, review or account activity for administrator review. A model-generated flag is **not proof of fraud** and must not by itself trigger an irreversible punitive action.

### 4.6 AI Result Storage and Auditability

Where AI output affects the user experience or a business decision, the relevant result may be stored in the embedded `ServiceRequest.recommendation` object.

Where practical, stored AI metadata should include:

- Provider identifier.
- Model/version identifier.
- Timestamp.
- Request/context reference.
- Result or recommendation data.
- Confidence or reliability information when provided.

Do not store unnecessary sensitive prompt or response content.

### 4.7 AI Failure and Fallback Policy

AI failure must never block the marketplace.

The implementation must safely handle:

- Timeout.
- Provider/API unavailability.
- Malformed output.
- Rate limiting.
- Authentication/configuration failure.
- Low-confidence output.
- Temporary network failure.

When AI is unavailable, the customer continues through the normal/manual discovery workflow. A fallback ranking algorithm may be used where it improves resilience, but it must not be presented as AI.

### 4.8 AI Quality and Bias Controls

The implementation should:

- Keep the customer in control of artisan selection.
- Avoid protected or irrelevant personal characteristics for ranking.
- Prefer business-relevant ranking factors.
- Provide understandable reasons where practical.
- Monitor recommendation behavior during testing.
- Allow administrators to investigate suspicious AI-related outcomes.

## 5. Business Rules

1. Customers choose artisans; the platform does not silently assign them.
2. AI is optional.
3. Manual artisan search is a first-class workflow.
4. AI cannot block request progression.
5. An artisan must be verified according to platform policy before receiving the platform's verified designation.
6. Inspection fees must not be duplicated for the same inspection.
7. Inspection may be required only where the service needs physical evaluation.
8. Customer approves job-specific materials.
9. Material cost increases require additional approval.
10. Payments go through the platform's approved payment integration.
11. CamPay is the selected external payment provider.
12. MTN Mobile Money and Orange Money are underlying channels where supported by CamPay; they are not separate application integrations in the architecture.
13. Payment release follows completion/dispute rules.
14. Payment operations require server-side verification and duplicate protection.
15. Customer and artisan can communicate through request-associated conversations.
16. Reviews are associated with completed service requests.
17. Disputes are administrator-managed.
18. Location assists discovery but does not automatically determine artisan selection.
19. Customer location may be manually entered when device location is unavailable or denied.
20. Sensitive credentials and payment secrets remain server-side.

---

## 6. Domain Model

The baseline contains 13 domain classes:

- `User`
- `Customer`
- `Artisan`
- `Administrator`
- `ServiceCategory`
- `Service`
- `ServiceRequest`
- `Conversation`
- `Message`
- `Payment`
- `Payout`
- `Review`
- `Dispute`

### 6.1 Role Associations

```text
User
├── Customer
├── Artisan
└── Administrator
```

### 6.2 Key domain associations

**Persistence mapping:** `User hasOne Customer`, `User hasOne Artisan` and `User hasOne Administrator` through `user_id`; each role document belongs to its user. A user may have both the Customer and Artisan associations, but an Administrator association is exclusive from those marketplace roles.

The preceding role diagram is a linked-document association model, not embedded role data or PHP inheritance.

```text
Administrator 1 → 0..* ServiceCategory : manages
Administrator 1 → 0..* Service : creates
ServiceCategory 1 → 0..* Service : contains
User 1 → 0..* ServiceRequest : submits
Service 1 → 0..* ServiceRequest : concerns
Artisan 1 → 0..* ServiceRequest : receives
ServiceRequest 1 → 0..1 Conversation : initiates
Conversation 1 → 1..* Message : contains
User 1 → 0..* Message : sends
ServiceRequest 1 → 0..* Payment : generates
User 1 → 0..* Payment : makes
Payment 1 → 0..1 Payout : produces
Artisan 1 → 0..* Payout : receives
ServiceRequest 1 → 0..1 Review : produces
Artisan 1 → 0..* Review : receives
ServiceRequest 1 → 0..* Dispute : generates
User 1 → 0..* Dispute : reports
Administrator 1 → 0..* Dispute : resolves
```

Do not introduce redundant direct Customer↔Artisan associations or circular directed association patterns.

### 6.3 Embedded ServiceRequest concepts

The following remain embedded objects/arrays within `ServiceRequest`:

- `inspection : Object`
- `quotation : Object`
- `materials : Array<Object>`
- `completion : Object`
- `recommendation : Object`

Do not create standalone `Escrow`, `Wallet`, `Commission`, `ServiceJob`, `MaterialRequest`, `ServiceLocation`, `CompletionConfirmation` or AI domain classes unless the approved analysis is deliberately changed.

---

## 7. Request State Model

Recommended states:

```text
Created
→ [optional AI] Analyzing
→ [optional AI] ArtisansRecommended
→ ArtisanSelected
→ [optional] InspectionScheduled
→ [optional] InspectionCompleted
→ QuotationPending
→ QuotationReceived
→ PaymentPending
→ Booked
→ InProgress
→ AwaitingConfirmation
→ Completed
```

Additional controlled paths include rejection, cancellation and dispute handling.

---

## 8. Payment State Model

The payment lifecycle must distinguish external payment processing from the application's release/holding workflow.

```text
Initiated
   ↓
Processing
   ├──→ Failed
   ├──→ Cancelled
   └──→ Held
          ├──→ Releasing → Released
          │                 └→ Failed
          ├──→ Refunding → Refunded
          ├──→ Refunding → PartiallyRefunded
          └──→ Disputed → UnderReview
                              ├→ Released
                              └→ Refunding
```

Additional controlled states such as `Expired` may be used where an actual payment authorization/timeout mechanism requires them.

### 8.1 Payment Holding Mechanism

`Held` is an **application-level payment state**. It must not automatically be described as legally regulated escrow.

The implementation must separate:

1. **Collection:** customer payment is processed through CamPay and the application records the verified transaction.
2. **Controlled release:** after approved completion/dispute conditions are satisfied, the application authorizes the appropriate release/payout workflow.
3. **Refund:** where a refund is approved, the application initiates the supported refund process.

The exact financial custody arrangement depends on the CamPay merchant/account configuration and applicable financial/legal requirements. The project must not claim that CamPay provides contractual escrow unless this is explicitly verified for the chosen account/service.

For the academic prototype, the application may demonstrate the `Held` state and release logic without claiming that it constitutes a production escrow service.

### 8.2 Payment Failure and Idempotency

The backend must handle CamPay timeout/provider errors, duplicate payment requests, duplicate callbacks/webhooks, repeated confirmation attempts, failed payout/release attempts, and approved full or partial refunds where supported.

Transaction references and idempotency controls must prevent duplicate financial actions.

### 8.3 Dispute Interaction

When a valid dispute affects a held payment, release must be prevented until the dispute is resolved according to the applicable business rule.

A dispute resolution may result in release, full refund or partial refund where supported by the implemented payment workflow.

## 9. Artisan Verification State Model

```text
Unverified → Pending → Verified
                    └→ Rejected → Pending (resubmission)
Verified → Suspended
```

---

## 9.1 Dispute State Model

Major dispute transitions are:

```text
Opened
  ↓
UnderReview
  ↓
AwaitingInformation
  ↓
UnderReview
  ├──→ Resolved
  └──→ Closed
```

A dispute may remain under review while evidence or clarification is collected. Payment release must respect the dispute outcome.

---

## 10. Location and Google Maps Integration

Google Maps Platform is the selected mapping/location capability.

The application should support:

- Device location permission.
- Interactive maps on Flutter Web and Mobile.
- Place search/autocomplete where useful.
- Geocoding/reverse geocoding where required.
- Backend coordinate validation.
- MongoDB GeoJSON `Point` storage.
- MongoDB `2dsphere` indexes for nearby artisan searches.
- Service areas for artisans.
- Manual location selection when permission is denied.

Platform-specific API-key restrictions should be applied:

- Android: package/SHA restrictions.
- iOS: bundle identifier restrictions.
- Web: HTTP referrer restrictions.
- Server-side web-service credentials must remain server-side.

Google Maps is an external service, not a fourth application tier.

Package choices such as `google_maps_flutter`, `geolocator`, Places and geocoding packages are implementation choices. Use maintained, compatible packages after inspecting the current project dependencies.

---

## 11. Security Requirements

Security is a core project requirement.

### 11.1 Authentication and Authorization

- Secure password hashing.
- API authentication.
- Role/permission checks on protected operations.
- Server-side authorization for every sensitive action.
- Token revocation/logout handling where applicable.
- Role switching validates that the requested role is assigned to the account. Switching to `artisan` additionally requires a complete artisan profile; role possession alone never bypasses verification rules for accepting work.

### 11.2 Validation

All client input must be validated server-side. Never trust IDs, prices, statuses, ownership claims or payment results supplied by Flutter.

### 11.3 Payment Security

- Verify payment results server-side.
- Use transaction references/idempotency controls.
- Prevent duplicate confirmation and duplicate payout.
- Never expose CamPay secret credentials to clients.
- Log important transaction events.

### 11.4 Data Protection

- Avoid unnecessary collection of sensitive data.
- Restrict access to verification information.
- Secure file uploads.
- Validate file type/size.
- Prevent unauthorized object access.

### 11.5 Auditing

Important events such as verification decisions, payment transitions, dispute decisions and security-relevant account events should be auditable.

### 11.6 API Security

Use rate limiting, authorization middleware, input validation, safe error messages and secure configuration/secrets management.

---

## 12. Architecture

### 12.1 Logical architecture

```text
Flutter Web / Flutter Mobile
            ↓ HTTPS REST
       Laravel REST API
            ↓
          MongoDB
```

### 12.2 Three-tier architecture

**Presentation tier:** Flutter Web and Flutter Mobile.

**Application tier:** Laravel REST API, authentication, authorization, business rules, services, AI orchestration, CamPay integration and Google server-side integration where required.

**Data tier:** MongoDB.

External APIs are integrations accessed through the application tier, not additional application tiers.

### 12.3 Flutter architecture

The Flutter application adopts MVVM for separation of concerns:

- Views: presentation/UI.
- ViewModels: presentation state and user-facing logic.
- Models: data representations.
- Services/repositories: API and external integration access.

Flutter Web and Mobile should share as much application logic and UI infrastructure as practical while respecting platform differences.

### 12.4 Laravel architecture

Use Laravel's MVC foundation with clear separation between controllers, validation, business services, authorization, persistence/repositories where justified, external integrations and resources/transformers.

Do not force an unnecessary architecture pattern when a simpler professional Laravel structure is clearer.

---

## 13. Technology Stack

| Area | Approved technology |
|---|---|
| Web | Flutter Web |
| Mobile | Flutter |
| Frontend language | Dart |
| Frontend architecture | MVVM adopted by project |
| Backend | Laravel REST API |
| Backend language | PHP |
| Database | MongoDB |
| Payment provider | CamPay API |
| Maps/location | Google Maps Platform |
| API communication | HTTPS/REST |
| Source control | Git |

The core stack is the current baseline. It may evolve when compatibility, security, maintainability, product needs or delivery evidence justify a coherent change.

---

## 14. Dependency Policy

Do not unnecessarily restrict implementation choices.

```text
Project analysis / requirements = current context; revise as needs evolve
Business rules = current operating rules; change deliberately and document impact
Domain model = current model; evolve through migrations and compatible APIs
Major architecture = current baseline; explain material impact before replacement
Core technology/provider decisions = current baseline; change when justified
Implementation technique = flexible
Secondary dependencies = flexible with justification
```

Codex may choose better packages, patterns, algorithms, caching strategies, API techniques, internal organization or testing tools when they improve professional quality and preserve the approved system behavior.

Before adding or replacing dependencies, inspect the existing project files and lock files and choose maintained, compatible solutions. Do not replace the approved core stack without explaining the architectural impact.

---

## 15. API Design

The API should be organized around clear resources and authenticated operations. Likely areas include:

- Authentication/users.
- Customer profiles.
- Artisan profiles and verification.
- Service categories/services.
- Service requests.
- Artisan discovery/recommendations.
- Inspections.
- Quotations/material approvals.
- Payments and payment verification.
- Payouts.
- Conversations/messages.
- Reviews.
- Disputes.
- Administrator reports/management.

Use consistent HTTP status codes, request validation, response structures and error handling.

Do not expose internal implementation details or secrets.

---

## 16. MongoDB Design

Use MongoDB as the authoritative application database.

### 16.1 Data rules

- MongoDB generates `_id`; do not model `_id` as an application-generated attribute.
- Use `ObjectId` for application references.
- Use GeoJSON for geospatial data.
- Use `2dsphere` indexes for geospatial queries.
- Embed tightly coupled request lifecycle data inside `ServiceRequest`.
- Create indexes based on actual query patterns.
- Enforce important business invariants in backend logic.

### 16.2 Recommended conceptual collections

Collections should correspond to the approved domain model and may include users/role profiles, service categories, services, service requests, conversations, messages, payments, payouts, reviews and disputes.

The exact physical collection structure and repository implementation may be optimized by Codex as long as the domain behavior remains unchanged.

### 16.3 Implemented role-collection design (2026-09-23)

The active role collections and their key indexes are:

- `users`: unique `email`, with account identity, credentials, `roles` and `active_role`.
- `customers`: unique `user_id`.
- `artisans`: unique `user_id`, `verification_status`, and GeoJSON `location` `2dsphere` indexes; service-offering discovery also uses a compound verification/service index.
- `administrators`: unique `user_id`.

The migration `2026_09_23_000000_create_separate_user_role_collections.php` backfills existing customer data, copies legacy `artisan_profiles` records into the active `artisans` collection, normalizes account-name/status fields, and preserves the legacy collection during the compatibility period. New application code uses `Artisan`; `ArtisanProfile` remains only as a temporary compatibility alias.

---

## 17. UI/UX Requirements

The interface must be professional, responsive and usable on budget smartphones as well as desktop browsers.

### Customer experience

- Fast service discovery.
- Clear request creation.
- Optional AI assistance.
- Clear manual search.
- Strong artisan profile presentation.
- Transparent quotation and material approval.
- Clear payment status.
- Request/job tracking.
- Communication.
- Completion confirmation.
- Review/dispute access.

### Artisan experience

- Simple onboarding.
- Verification workflow.
- Professional profile.
- Service management.
- Availability.
- Request management.
- Inspection/quotation tools.
- Material requests.
- Job progress.
- Earnings/payout visibility.

### Administrator experience

- Dashboard.
- User management.
- Verification review.
- Catalog management.
- Dispute handling.
- Payment/transaction oversight.
- Reports and audit visibility.

Use the approved UI workflow and project design assets where provided. Frontend screens must represent real backend capabilities rather than mocked workflows presented as complete functionality.

---

## 18. Cameroon-Specific Design Considerations

- Mobile-first usability.
- Support variable connectivity.
- Avoid unnecessarily heavy pages and requests.
- Make location entry possible without device GPS.
- Reflect local trust concerns around allowing an artisan into a home/property.
- Make verification and reputation visible.
- Support transparent negotiation rather than assuming fixed pricing for every service.
- Support MTN/Orange payment channels through CamPay where available.
- Give artisans a credible digital professional presence.
- Keep the language and workflows understandable to local users.

---

## 19. UML Alignment and Current Modeling Scope

UML remains an important design reference and must remain consistent with the implemented system.

Required/maintained UML artifacts include:

- General Use Case Diagram.
- Detailed Use Case descriptions/diagrams where needed.
- At least three Activity Diagrams.
- State Machine Diagrams for major lifecycle entities.
- Sequence Diagrams for important workflows.
- Package Diagram.
- Component Diagram.
- Deployment Diagram.

### 19.1 Class Diagram — Deferred Representation

The **visual UML representation of the class diagram is deferred from the current implementation period**. It should not block backend development or frontend development.

The approved domain model nevertheless remains an implementation reference. The actual domain concepts, relationships, attributes and embedded MongoDB structures must be implemented consistently in code.

During development, the class diagram may be produced/refined from the implemented and validated domain model when that activity returns to scope.

### 19.2 Embedded MongoDB Concepts

`inspection`, `quotation`, `materials`, `completion` and `recommendation` remain embedded within `ServiceRequest`.

They do not require standalone application/domain classes or collections merely to make UML representation easier.

### 19.3 Activity and Sequence Modeling

Activity diagrams model specific use cases rather than the entire system. Appropriate swimlanes include `User`, `System`, `DBMS` and `API` where applicable.

Authentication should not be unnecessarily repeated in every activity diagram; reference the dedicated authentication workflow.

Sequence diagrams should focus on critical interactions such as payment initiation/verification and release, optional AI recommendation, dispute handling, and other high-risk external-service workflows as required.

### 19.4 Deployment Diagram — Architectural Reference Only

The deployment diagram describes the intended deployment architecture, but **deployment itself is not part of the current implementation period**. It is an architectural specification rather than a task requiring production hosting during this period.

## 20. Development Strategy — Backend First

This is a **non-negotiable development sequencing principle**.

The implementation must proceed in this order:

```text
Requirements / UML
        ↓
MongoDB Data Model / Indexes
        ↓
Laravel Backend Foundation
        ↓
Authentication / Authorization
        ↓
Core Backend Modules
        ↓
Backend API Testing & Stabilization
        ↓
Flutter Frontend
        ↓
Backend–Frontend Integration
        ↓
End-to-End Testing
        ↓
Final QA / Hardening
```

### 20.1 Backend-first meaning

The backend is the source of truth for business behavior. Before substantial frontend feature development begins, the backend must have a stable foundation covering the core domain, authentication, authorization, validation, request lifecycle and required external integrations.

Small frontend scaffolding or integration experiments are allowed when they help verify an API or unblock development, but the frontend must not become the primary implementation before the backend foundation is sufficiently implemented and tested.

### 20.2 Backend implementation scope

The backend should establish:

- MongoDB models/data access.
- Indexes.
- Authentication.
- Role/permission enforcement.
- Service catalog.
- Customer/artisan profiles.
- Verification.
- Service requests and lifecycle.
- Manual artisan discovery.
- Optional AI services.
- Inspection.
- Quotations.
- Materials approval.
- CamPay payment integration.
- Completion/release/payout workflow.
- Communication.
- Reviews.
- Disputes.
- Validation/error handling.
- Security controls.
- Auditing where required.
- Automated/integration tests.

---

## 21. Professional Software Quality Standard

ServiceHUB must be built to professional software-engineering standards. A collection of working screens is not considered a completed implementation.

The implementation must demonstrate:

- Clean and maintainable code.
- Separation of concerns.
- Appropriate architecture.
- Secure authentication and authorization.
- Strong server-side validation.
- Consistent APIs.
- Robust error handling.
- Database integrity and appropriate indexing.
- Automated and integration tests.
- Secure external API integration.
- Payment idempotency/duplicate protection.
- Safe handling of secrets.
- Auditability of important operations.
- Responsive Web/Mobile UI.
- Usability and accessibility awareness.
- Reasonable performance.
- Maintainable documentation.
- Meaningful logging and diagnostics.
- Production-minded configuration practices.

The standard is: **it must work correctly, securely, maintainably and predictably — not merely look complete.**

---

## 22. Implementation Phases

### Phase 1 — Analysis and preparation

- Confirm requirements and business rules.
- Maintain approved UML models that are currently in scope.
- Confirm the domain model as the implementation reference.
- Establish the local development environment and repositories.
- Do not delay implementation solely because the class-diagram visual representation is deferred.

### Phase 2 — MongoDB and backend foundation

- Configure Laravel.
- Configure MongoDB.
- Establish data access patterns.
- Add indexes, including required geospatial indexes.
- Configure authentication and authorization.
- Establish validation, error-handling and API conventions.
- Resolve local PHP/MongoDB runtime requirements.

### Phase 3 — Core marketplace backend

Implement profiles, artisan verification, service catalog, service requests, manual discovery/search/filtering, artisan selection and request lifecycle.

### Phase 4 — Transactions and trust

Implement inspection, quotations, materials approval, CamPay payment integration, payment verification/idempotency, completion confirmation, controlled release/payout workflow, reviews and disputes.

### Phase 5 — Communication

Implement conversations, messages, authorization and attachment handling where required.

### Phase 6 — AI services

Implement optional AI capabilities in priority order:

1. Request understanding.
2. Artisan recommendation/ranking.
3. Quotation analysis.
4. Security anomaly detection.

The first two receive priority because they directly support the project's academic AI contribution.

AI must not delay or block the normal marketplace workflow.

### Phase 7 — Backend stabilization

Before substantial frontend implementation:

- Complete backend automated tests.
- Complete API/integration tests.
- Test security controls.
- Test payment failure/retry/idempotency paths.
- Test geospatial queries.
- Test AI fallback.
- Review API error handling.
- Perform reasonable performance checks.
- Document stable API behavior.

### Phase 8 — Flutter frontend

Build Customer, Artisan and Administrator interfaces against the stable backend API. Use Flutter Web and Flutter Mobile with shared architecture where practical. Use Stitch for significant UI design work.

### Phase 9 — Integration and final QA

Validate complete marketplace workflows, payment callbacks/results, location features, permissions, error paths, AI fallback, responsive behavior and security.

### Phase 10 — Deployment Preparation (Deferred)

Deployment architecture must be documented, but actual production deployment is **outside the current implementation period**.

When deployment enters scope, it should cover production hosting, MongoDB Atlas production configuration, HTTPS, environment separation, secret management, production CamPay configuration, production Google Maps configuration, backups/recovery, monitoring and CI/CD where appropriate.

No production hosting or CI/CD work should be treated as a prerequisite for completing the current development period unless the project scope is explicitly changed.

## 23. Testing Strategy

Testing is part of implementation, not an optional final activity.

### 23.1 Unit Tests

Cover business rules, state transitions, validation, deterministic recommendation/ranking logic, payment calculations/safeguards, material approval rules and commission calculations where applicable.

### 23.2 API/Integration Tests

Cover authentication, authorization, request lifecycle, artisan selection, inspection/quotation/material approval, payment initiation/verification, completion/release/payout, reviews/disputes, communication and relevant location behavior.

### 23.3 Security Tests

Cover unauthorized access, IDOR/object ownership, invalid role operations, input validation, file upload abuse, payment replay/duplication, secret exposure, rate-limit behavior and unexpected external API responses.

### 23.4 AI Failure/Fallback Tests

Simulate AI timeout, provider failure, malformed output, low-confidence output, rate limiting and missing configuration. Verify that the normal/manual workflow remains usable in every case.

### 23.5 Payment Failure and Concurrency Tests

Test CamPay timeout/error, duplicate payment submission, duplicate callback/webhook, payment reversal/failure where supported, duplicate payout attempts, simultaneous artisan selection, simultaneous request updates and concurrent payment actions.

### 23.6 Geospatial Tests

Verify GeoJSON validation, `2dsphere` queries, nearby-artisan searches, location filtering, denied location permission and manual location entry/selection.

### 23.7 Performance Testing

Measure API response time, database query performance, geospatial query performance, payment workflow latency, AI recommendation latency and frontend responsiveness under representative prototype conditions.

Numerical performance targets are validation targets for the prototype, not guaranteed production-capacity claims.

### 23.8 Disaster Recovery Testing — Deferred

Formal production disaster-recovery and backup/restore testing are not part of the current implementation period. The architecture should nevertheless document the intended approach for later deployment.

### 23.9 Frontend Tests

Cover ViewModel logic, important UI states, API error handling, authentication state, responsive behavior and platform-specific Web/Mobile behavior.

### 23.10 End-to-End Tests

At minimum validate:

1. Customer registration/login.
2. Artisan registration/verification.
3. Manual request → search → artisan selection.
4. AI-assisted request → recommendations → customer selection.
5. Inspection → quotation → materials approval.
6. Payment → booking → execution → completion → release/payout.
7. Review.
8. Dispute.
9. AI failure → normal workflow continues.

### 23.11 Accessibility Testing

Check readable typography, adequate touch targets, keyboard navigation on Web where applicable, form labels/validation feedback, clear error messages, responsive layouts and usability on budget smartphones.

## 24. Non-Functional Requirements

The following are quality objectives for implementation and validation.

### 24.1 Performance

- APIs should respond efficiently under representative prototype workloads.
- Frequently used database queries should be indexed appropriately.
- Geospatial searches should use `2dsphere` indexes.
- AI operations must not unnecessarily block normal request processing.
- Flutter should remain usable on variable and low-bandwidth connections.

### 24.2 Scalability

The design should avoid unnecessary assumptions that prevent future growth. Specific production capacity figures are not required during the current implementation period.

### 24.3 Availability and Resilience

- Gracefully handle temporary external-service failures.
- Preserve data consistency when CamPay or AI services are unavailable.
- Avoid making external services single points of failure for unrelated marketplace functions.
- Manual discovery remains available when AI fails.

Production uptime commitments are outside the current implementation period.

### 24.4 Security

Use HTTPS, secure authentication/authorization, server-side validation, secure file handling, object-access protection, payment idempotency, secret protection and auditability of important financial/security events.

### 24.5 Usability

Support responsive Web/Mobile interfaces, clear loading/empty/success/error states, non-technical users, low-cost smartphones and variable connectivity.

### 24.6 Maintainability

Use clear separation of concerns, consistent coding standards, reusable components, automated tests, meaningful comments around complex business rules and documentation aligned with implementation.

### 24.7 Compliance

Avoid unnecessary sensitive-data collection and respect applicable Cameroonian data-protection and payment requirements. Specific legal retention periods or regulatory claims must be confirmed before production deployment.

---

## 25. Data Retention, Deletion and Privacy

### 25.1 Retention Principles

Retention periods must be based on legal/regulatory requirements, business necessity, dispute/audit requirements, payment-provider requirements and security requirements. Do not invent fixed retention periods where the requirement has not been established.

### 25.2 Account Deletion

Where account deletion is supported:

- Prevent continued normal account access.
- Preserve records that must remain available.
- Anonymize personal information where appropriate.
- Preserve financial/dispute records where required.
- Ensure deleted/deactivated users cannot be treated as active artisans.

### 25.3 Sensitive Information

Verification information and other sensitive data must be accessible only to authorized roles and should not be unnecessarily exposed through API responses or logs.

---

## 26. Error Handling Standards

The backend must provide consistent, safe and actionable errors.

### 26.1 Error Response

A consistent structure should be used, for example:

```json
{
  "success": false,
  "error": {
    "code": "PAYMENT_FAILED",
    "message": "Payment could not be processed.",
    "details": {},
    "requestId": "generated-request-id",
    "timestamp": "server-generated-timestamp"
  }
}
```

The exact structure may be refined during implementation if consistency is preserved.

### 26.2 Common Error Categories

| Code | HTTP Status | Meaning |
|---|---:|---|
| `VALIDATION_ERROR` | 422 | Invalid input |
| `UNAUTHORIZED` | 401 | Authentication required |
| `FORBIDDEN` | 403 | Insufficient permission |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Business/resource conflict |
| `PAYMENT_FAILED` | 400/502 | Payment operation failed |
| `AI_UNAVAILABLE` | 503 | AI service unavailable |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Unexpected server error |

Provider-specific status codes may be refined during implementation.

### 26.3 Error Logging

Logs should include timestamp, request/correlation ID, safe user reference where appropriate, error code/category and sanitized context. Stack traces are appropriate in development. Never log secrets, access tokens, passwords, payment credentials or unnecessary sensitive information.

### 26.4 User-Facing Errors

Messages should be non-technical, actionable, localizable and free of sensitive implementation details.

---

## 27. API Rate Limiting and Abuse Protection

Rate limits should protect high-risk endpoints without making the normal application unusable.

Priority areas include authentication, AI requests, payment initiation, verification operations and general API access.

Exact limits are implementation parameters and should be selected after observing actual request patterns and testing requirements.

---

## 28. Monitoring and Diagnostics

During the current implementation period, monitoring is limited to **development diagnostics and application logging**.

Important observable events include authentication failures, authorization failures, payment/payout events, external API failures, AI failures, disputes and security-relevant account events.

Production monitoring platforms, real-time alerting and operational dashboards are deployment-phase concerns and are not required during the current period.

---

## 29. Deployment Architecture — Specification Only

Deployment architecture is documented for architectural completeness, but **no production deployment is required during the current implementation period**.

### 29.1 Intended Deployment

```text
INTERNET
  ├── Smartphone
  │     └── Flutter Mobile
  │
  └── Computer/Tablet Browser
        └── Flutter Web
                 │ HTTPS
                 ▼
        Application/Web Server
          ├── Web server/reverse proxy
          ├── Flutter Web assets
          ├── PHP runtime
          └── Laravel REST API
                 ├── HTTPS → MongoDB deployment
                 ├── HTTPS → CamPay API
                 └── HTTPS → Google Maps services where required
```

### 29.2 Intended Production Environment

The eventual production environment should provide secure HTTPS, Laravel/PHP runtime, MongoDB managed or securely hosted deployment, secure environment configuration, production CamPay credentials, restricted Google Maps API keys, backups, logging and monitoring.

MongoDB Atlas remains the recommended managed MongoDB deployment option.

### 29.3 Environment Separation

When deployment enters scope:

```text
Development → Staging → Production
```

Each environment should have appropriate database, API credentials, Maps configuration, CamPay configuration and secrets.

### 29.4 CI/CD

A future pipeline may follow:

```text
Git Push → Automated Tests → Build → Staging → Verification → Production
```

CI/CD implementation is deferred.

### 29.5 Backup and Recovery

A production deployment should define automated MongoDB backups, retention, restore procedures, recovery objectives and recovery testing. Formal production backup/recovery implementation is deferred.

---

## 30. Codex Working Principles

Codex must work incrementally and inspect the existing code before changing it.

For every feature:

```text
Understand requirement
→ Inspect existing implementation
→ Design the smallest coherent change
→ Implement backend
→ Test backend
→ Stabilize
→ Implement/integrate frontend
→ Test integration
→ Review security/quality
→ Report completion
```

Do not rewrite working modules unnecessarily.

Do not add dependencies merely because they are convenient. However, do not impose artificial restrictions: if a maintained compatible package or implementation approach is demonstrably better, Codex may use it while preserving the approved architecture and business rules.

When a change would affect a major architectural decision, business rule, domain model, security model or core provider, explain the impact before changing it.

---

## 31. Completion Criteria

### 31.1 Current Implementation-Period Completion

The current implementation period is complete when:

- The approved backend is implemented and tested.
- Core business rules are enforced server-side.
- Authentication and authorization are secure.
- MongoDB persistence and indexes are correct.
- Manual marketplace discovery works.
- Optional AI assistance works without blocking manual workflows.
- Artisan verification works.
- Inspection/quotation/material workflows work.
- CamPay payment integration works at the prototype level supported by the available environment.
- Payment duplicate protection is implemented.
- Completion/release/payout logic works at the implemented prototype level.
- Communication works.
- Reviews and disputes work.
- Google Maps/location functionality works where required.
- Flutter Web and Mobile interfaces are integrated with the backend.
- Critical automated/integration tests pass.
- Security and error-path testing has been performed.
- Documentation remains aligned with implementation.
- The code meets professional quality standards.

The following are **not required for current-period completion**:

- Production deployment.
- Production hosting.
- CI/CD deployment.
- Production monitoring infrastructure.
- Formal production disaster-recovery implementation.
- Production-scale load certification.
- Final visual UML class diagram, where that artifact remains deferred by project scope.

### 31.2 Eventual Production Completion

Before a real production launch, the project should additionally complete production deployment, production secret management, production CamPay configuration and financial/legal validation, production Google Maps configuration, backup/restore procedures, monitoring/alerting, operational security review, performance/load validation appropriate to expected traffic, and final UML documentation including the class diagram.

### 31.3 Implementation Decision Register

This register records current implementation decisions so the guide remains aligned with the backend. It is updated with each material module change and may be revised when evidence, user needs, security or delivery priorities change.

| Date | Decision | Rationale / consequence |
|---|---|---|
| 2026-09-09 to 2026-09-14 | Laravel uses the official MongoDB Laravel integration with BSON-native embedded structures and index-focused migrations. | MongoDB is the authoritative datastore. JSON-string array casts were migrated to BSON arrays; migrations use MongoDB blueprints and collection indexes. |
| 2026-09-09 to 2026-09-12 | Core marketplace, lifecycle, geospatial discovery/geocoding, CamPay collection/payout, controlled release, reviews, disputes and request conversations were implemented backend-first. | Financial transitions are server-authorized, idempotency-aware and auditable; AI remains advisory with deterministic/manual fallbacks. |
| 2026-09-12 to 2026-09-14 | Private attachments, account-status controls, rate limits, audit logging and administrator reporting were implemented. | Sensitive files are private and authorization-gated; admin reports sanitize sensitive payloads; high-risk API areas are throttled. |
| 2026-09-23 | Customer, artisan and administrator data moved to linked active role collections, with dual customer/artisan roles and `active_role`. | This replaces embedded role-profile persistence, permits dashboard switching without duplicate accounts, preserves separate customer-payment and artisan-payout ledgers, and keeps administrator accounts exclusive. |
| 2026-09-23 | Customer profile photos, password change/reset and recipient notification APIs were completed. | Photos remain private and ownership-gated; password reset responses do not disclose account existence and credential changes revoke tokens; notifications are paginated, ownership-scoped and sanitized before response. |
| 2026-09-29 | Service requests use an explicit, deterministic artisan-selection lifecycle. | New requests are matched without AI and remain customer-selectable; no-match is recoverable, selection/decline/change/timeout events are retained, and a scheduled command expires unanswered selections using the configurable 24-hour default. Legacy inspection states remain supported for requests already in that workflow. |
| 2026-09-29 | `users.phone` is unique only for string values. | The MongoDB phone index is a partial unique index filtered by `$type: 'string'`, allowing email-only accounts and legacy `null` values while preventing duplicate supplied phone numbers. |
| 2026-09-29 | Service requests persist the customer’s optional AI-assist preference. | `ai_assist_enabled` defaults to false and records whether AI-based artisan ranking may be offered; deterministic eligibility and manual selection remain authoritative. |
| 2026-09-30 | AI-assisted artisan rankings are generated only at request submission and stored as advisory recommendations. | Only deterministic-eligible artisans are sent to the configured AI agent; output is sanitized, capped at three, failure-safe, and never alters request status or artisan assignment. |
| 2026-09-30 | Laravel AI responses are type-guarded before structured output is consumed. | `Promptable::prompt()` is declared as returning `AgentResponse`; ServiceHUB now calls `toArray()` only after verifying `StructuredAgentResponse`, so unexpected provider output follows existing advisory fallbacks. |
| 2026-09-30 | Customer request tracking uses a server-normalized payload and calculated artisan-response expiry. | The tracking endpoint exposes safe request/artisan details, a sanitized timeline, permitted next action and `pending_response.expires_at`; Flutter does not infer timeout or lifecycle permissions. |
| 2026-09-30 | Customer self-service editing, rescheduling and cancellation are limited to pre-acceptance lifecycle states. | Request-detail/preferred-schedule changes are allowed only while selecting or recovering matching and always re-run deterministic matching. Direct cancellation is auditable until quotation acceptance; after acceptance, payment support/dispute handling is required. |
| 2026-10-02 | Documentation and implementation are managed as living project artifacts. | Existing guidance, contracts and code are current context rather than immutable authority; material changes remain impact-reviewed, implemented coherently, and documented after validation. |

---

## Final Principle

**Keep ServiceHUB coherent, secure and useful; adapt its implementation deliberately as requirements and evidence evolve.**

The guide, contracts and existing code are living references. Product requirements, business rules, domain models, architecture, technologies and provider choices may evolve when doing so improves the product, security, maintainability, compatibility or delivery. Material changes must be impact-reviewed, implemented consistently across backend and Flutter, tested proportionately, and recorded here.
