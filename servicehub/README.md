<p align="center"><a href="https://laravel.com" target="_blank"><img src="https://raw.githubusercontent.com/laravel/art/master/logo-lockup/5%20SVG/2%20CMYK/1%20Full%20Color/laravel-logolockup-cmyk-red.svg" width="400" alt="Laravel Logo"></a></p>

<p align="center">
<a href="https://github.com/laravel/framework/actions"><img src="https://github.com/laravel/framework/workflows/tests/badge.svg" alt="Build Status"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/dt/laravel/framework" alt="Total Downloads"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/v/laravel/framework" alt="Latest Stable Version"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/l/laravel/framework" alt="License"></a>
</p>

## ServiceHUB AI provider setup

ServiceHUB's AI features are optional and server-side only. They never select an artisan, alter a quotation, or block a payment.

1. Create an API project and key in the OpenAI Platform.
2. Add `OPENAI_API_KEY` to the server-only `.env` file; never put it in Flutter or commit it.
3. Set `OPENAI_STORE=false` unless provider-side response storage is explicitly required.
4. Confirm account eligibility, usage limits, and billing in the OpenAI Platform before enabling AI. Do not rely on unverified free-tier claims.

Only minimal request, candidate, and payment metadata is sent to the provider. Do not send payout phones, credentials, verification documents, contact details, or uploaded files. When AI is unavailable, manual workflows remain available and recommendations use a deterministic fallback.

## Payment architecture

ServiceHUB keeps payment credentials exclusively in the Laravel environment. Normal customer collection, transaction-status reconciliation, and an undisputed artisan payout use the CamPay gateway. The backend is the only component that invokes CamPay; Flutter and web clients receive only application payment states and safe transaction metadata.

CamPay's documented collection and withdrawal workflows are used for the normal demo path. A full refund and a split refund-plus-payout cannot be made atomic with the documented CamPay operations, so dispute resolution deliberately uses a separate simulated provider for those paths. A simulated provider result always contains `is_simulated: true`, uses a `SIM-` reference, and is labelled **SIMULATED — no real funds moved** in admin-facing API data. Simulation is never substituted for normal collection or normal payout.

Configure the real gateway only through server-side environment variables:

```dotenv
CAMPAY_BASE_URL=https://demo.campay.net/api
CAMPAY_USERNAME=server_only_application_username
CAMPAY_PASSWORD=server_only_application_password
CAMPAY_WEBHOOK_SECRET=server_only_webhook_key
# Test only: refund, disburse, or both.
CAMPAY_SIMULATION_FAIL_ON=
```

The CamPay webhook endpoint is `POST /api/webhooks/campay`. It fails closed until `CAMPAY_WEBHOOK_SECRET` is configured, validates the signed callback, and checks the recorded provider reference, external reference, amount, and XAF currency before it reconciles a payment or payout. Do not enable this endpoint until the webhook key has been configured in the CamPay dashboard.

## Commission policy

The commission rate is an administrator-controlled platform setting, not a hardcoded business constant. It defaults to 7% and is validated between 0% and 30%. Updating it requires an audit reason and creates a retained audit record.

At payment creation, ServiceHUB snapshots `commission_rate_snapshot`, `commission_amount`, `artisan_gross_amount`, and `artisan_net_amount`. Later settings changes never affect existing payments. The commission is deducted from the artisan's gross release, never added to the customer-held amount. Payments created before the snapshot feature are explicitly treated as legacy transactions and are never recalculated retroactively.

## Dispute financial resolution policy

Only an administrator with `manage-disputes` may resolve an under-review dispute, and the reporting user may not resolve their own dispute. The payment must still be `held`. These are the only outcomes:

| Decision | Customer refund | Artisan gross | Commission |
| --- | ---: | ---: | ---: |
| `refund_customer` | held amount | 0 | 0 |
| `release_artisan` | 0 | held amount | snapshot rate × held amount |
| `split_resolution` | X | held amount − X | snapshot rate × artisan gross |
| `hold` | 0 | 0 | 0 |

For every split, `customer_refund_amount + artisan_gross_release` must exactly equal the held amount in whole XAF. The server derives every commission and net amount; clients cannot submit them.

Financial decisions use two-step confirmation: `POST /api/admin/disputes/{id}/resolve` records a 15-minute `pending_execution` decision, and `POST /api/admin/disputes/{id}/confirm-resolution` performs it. Each decision requires a globally unique UUID v4 `resolution_reference`. The scheduler expires unconfirmed decisions back to `under_review`; run `php artisan schedule:work` (or your production scheduler) so this safeguard is active.

```text
Payment
held → releasing → released                         (real full payout)
held → refunding → refunded                          (simulated full refund)
held → refunding → releasing → partially_refunded    (simulated split success)
held → refunding → releasing → reconciliation_required (simulated split partial failure)

Dispute
opened → under_review → pending_execution → resolved
                  └──────────────→ under_review      (cancel/15-minute expiry)
under_review → under_investigation → under_review
under_review → reconciliation_required → resolved    (administrator reconciliation)
```

When a simulated split refund succeeds but the simulated payout fails, the state is `reconciliation_required`—never `held`. An administrator must review and reconcile the recorded outcome using `POST /api/admin/disputes/{id}/reconcile`. This prevents the system from asserting that funds were restored after a partial operation. Every initiation, confirmation, cancellation, timeout, execution, failure, and reconciliation writes an immutable audit record retained for five years. In-app notifications inform the relevant parties without exposing internal administrator notes.

## About Laravel

Laravel is a web application framework with expressive, elegant syntax. We believe development must be an enjoyable and creative experience to be truly fulfilling. Laravel takes the pain out of development by easing common tasks used in many web projects, such as:

- [Simple, fast routing engine](https://laravel.com/docs/routing).
- [Powerful dependency injection container](https://laravel.com/docs/container).
- Multiple back-ends for [session](https://laravel.com/docs/session) and [cache](https://laravel.com/docs/cache) storage.
- Expressive, intuitive [database ORM](https://laravel.com/docs/eloquent).
- Database agnostic [schema migrations](https://laravel.com/docs/migrations).
- [Robust background job processing](https://laravel.com/docs/queues).
- [Real-time event broadcasting](https://laravel.com/docs/broadcasting).

Laravel is accessible, powerful, and provides tools required for large, robust applications.

## Learning Laravel

Laravel has the most extensive and thorough [documentation](https://laravel.com/docs) and video tutorial library of all modern web application frameworks, making it a breeze to get started with the framework.

In addition, [Laracasts](https://laracasts.com) contains thousands of video tutorials on a range of topics including Laravel, modern PHP, unit testing, and JavaScript. Boost your skills by digging into our comprehensive video library.

You can also watch bite-sized lessons with real-world projects on [Laravel Learn](https://laravel.com/learn), where you will be guided through building a Laravel application from scratch while learning PHP fundamentals.

## Agentic Development

Laravel's predictable structure and conventions make it ideal for AI coding agents like Claude Code, Cursor, and GitHub Copilot. Install [Laravel Boost](https://laravel.com/docs/ai) to supercharge your AI workflow:

```bash
composer require laravel/boost --dev

php artisan boost:install
```

Boost provides your agent 15+ tools and skills that help agents build Laravel applications while following best practices.

## Contributing

Thank you for considering contributing to the Laravel framework! The contribution guide can be found in the [Laravel documentation](https://laravel.com/docs/contributions).

## Code of Conduct

In order to ensure that the Laravel community is welcoming to all, please review and abide by the [Code of Conduct](https://laravel.com/docs/contributions#code-of-conduct).

## Security Vulnerabilities

If you discover a security vulnerability within Laravel, please send an e-mail to Taylor Otwell via [taylor@laravel.com](mailto:taylor@laravel.com). All security vulnerabilities will be promptly addressed.

## License

The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
