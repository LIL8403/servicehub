import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servicehub_frontend/features/admin/presentation/pages/admin_audit_logs_page.dart';
import 'package:servicehub_frontend/features/admin/presentation/pages/admin_disputes_page.dart';
import 'package:servicehub_frontend/features/admin/presentation/pages/admin_payments_page.dart';
import 'package:servicehub_frontend/features/admin/presentation/pages/admin_payouts_page.dart';
import 'package:servicehub_frontend/features/admin/presentation/pages/admin_platform_settings_page.dart';
import 'package:servicehub_frontend/features/admin/presentation/pages/admin_service_requests_page.dart';
import 'package:servicehub_frontend/features/admin/presentation/pages/admin_services_page.dart';
import 'package:servicehub_frontend/features/admin/presentation/pages/admin_verification_page.dart';
import 'package:servicehub_frontend/features/artisan/presentation/pages/artisan_availability_page.dart';
import 'package:servicehub_frontend/features/artisan/presentation/pages/artisan_service_offerings_page.dart';
import '../../../../features/admin/presentation/pages/admin_shell_page.dart';
import '../../../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../../../features/admin/presentation/pages/admin_categories_page.dart';
import '../../../../features/admin/presentation/pages/admin_coming_soon_page.dart';
import '../../../../features/admin/presentation/pages/admin_users_page.dart';
import 'package:servicehub_frontend/features/artisan/presentation/pages/artisan_professional_review_page.dart';
import 'package:servicehub_frontend/features/artisan/presentation/pages/artisan_profile_editor_page.dart';
import 'package:servicehub_frontend/features/artisan/presentation/pages/artisan_submission_review_page.dart';
import 'package:servicehub_frontend/features/artisan/presentation/pages/artisan_supporting_documents_page.dart';
import 'package:servicehub_frontend/features/artisan/presentation/pages/artisan_verification_page.dart';
import 'package:servicehub_frontend/features/customer/presentation/pages/customer_payment_history_page.dart';
import '../../../../features/customer/presentation/pages/artisan_map_page.dart';

import '../../../../features/artisan/presentation/pages/artisan_materials_form_page.dart';
import '../../../../features/artisan/presentation/pages/artisan_quotation_form_page.dart';
import '../../../../features/artisan/presentation/pages/artisan_report_completion_page.dart';
import '../../../../features/artisan/presentation/pages/artisan_request_detail_page.dart';
import '../../../../features/artisan/presentation/pages/artisan_shell_page.dart';
import '../../../../features/artisan/presentation/pages/artisan_home_tab.dart';
import '../../../../features/artisan/presentation/pages/artisan_requests_tab.dart';
import '../../../../features/artisan/presentation/pages/artisan_messages_tab.dart';
import '../../../../features/artisan/presentation/pages/artisan_earnings_tab.dart';
import '../../../../features/artisan/presentation/pages/artisan_profile_tab.dart';
import '../../../../features/artisan/presentation/pages/artisan_identity_form_page.dart';
import '../../../../features/artisan/presentation/pages/artisan_id_document_page.dart';
import '../../../../features/artisan/presentation/pages/artisan_selfie_capture_page.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../../../../features/auth/presentation/pages/register_page.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/customer/presentation/pages/artisan_profile_page.dart';
import '../../../../features/customer/presentation/pages/artisan_public_profile_page.dart';
import '../../../../features/customer/presentation/pages/artisan_selection_page.dart';
import '../../../../features/customer/presentation/pages/conversation_page.dart';
import '../../../../features/customer/presentation/pages/create_request_page.dart';
import '../../../../features/customer/presentation/pages/customer_discover_tab.dart';
import '../../../../features/customer/presentation/pages/customer_home_tab.dart';
import '../../../../features/customer/presentation/pages/customer_messages_tab.dart';
import '../../../../features/customer/presentation/pages/customer_profile_tab.dart';
import '../../../../features/customer/presentation/pages/customer_requests_tab.dart';
import '../../../../features/customer/presentation/pages/customer_shell_page.dart';
import '../../../../features/customer/presentation/pages/leave_review_page.dart';
import '../../../../features/customer/presentation/pages/report_issue_page.dart';
import '../../../../features/customer/presentation/pages/request_sent_page.dart';
import '../../../../features/customer/presentation/pages/request_success_page.dart';
import '../../../../features/customer/presentation/pages/request_tracking_page.dart';
import '../../../../features/customer/presentation/pages/service_categories_page.dart';
import '../../../../features/landing/presentation/pages/landing_page.dart';
import '../../../../features/splash/presentation/pages/splash_page.dart';
import 'auth_redirect.dart';

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final routerRefreshNotifierProvider = Provider<GoRouterRefreshNotifier>((ref) {
  final notifier = GoRouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final redirectParam = state.uri.queryParameters['redirect'];

      return AuthRedirect.redirect(
        isAuthenticated: authState is AuthAuthenticated,
        isLoading: authState is AuthLoading,
        location: state.matchedLocation,
        fullLocation: state.uri.toString(),
        redirectParam: redirectParam,
        homeRoute: authState.homeRoute,
      );
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const SplashPage()),
      GoRoute(path: '/landing', builder: (c, s) => const LandingPage()),
      GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterPage()),

      // ================================================================
      // Customer shell with five tabs
      // ================================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return CustomerShellPage(navigationShell: navigationShell);
        },
        branches: [
          // Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer-home',
                builder: (c, s) => const CustomerHomeTab(),
                routes: [
                  // Detail sub-routes nested under Home so back
                  // returns to the Home tab.
                  ..._serviceRequestRoutes(),
                ],
              ),
            ],
          ),
          // Discover
          // Discover
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer-home/discover',
                builder: (c, s) => const CustomerDiscoverTab(),
                routes: [
                  GoRoute(
                    path: 'map',
                    builder: (c, s) => const ArtisanMapPage(),
                  ),
                ],
              ),
            ],
          ),
          // Requests
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer-home/requests',
                builder: (c, s) => const CustomerRequestsTab(),
                routes: [..._serviceRequestRoutes()],
              ),
            ],
          ),
          // Messages
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer-home/messages',
                builder: (c, s) => const CustomerMessagesTab(),
                routes: [
                  GoRoute(
                    path: 'chat/:conversationId',
                    builder: (c, s) {
                      final serviceRequestId =
                          s.uri.queryParameters['serviceRequestId'] ?? '';
                      final artisanName =
                          s.uri.queryParameters['artisanName'] ?? 'Artisan';

                      // Reuse the existing ConversationPage. It takes a
                      // request id and opens the conversation for that
                      // request. Since conversations are 1:1 with
                      // requests, this is the correct identifier.
                      return ConversationPage(
                        requestId: serviceRequestId,
                        artisanName: artisanName,
                        artisanTitle: null,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer-home/profile',
                builder: (c, s) => const CustomerProfileTab(),
                routes: [
                  GoRoute(
                    path: 'payments',
                    builder: (c, s) => const CustomerPaymentHistoryPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ================================================================
      // Artisan home
      // ================================================================
      // ================================================================
      // Artisan shell with five tabs
      // ================================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ArtisanShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/artisan-home',
                builder: (c, s) => const ArtisanHomeTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/artisan-home/requests',
                builder: (c, s) => const ArtisanRequestsTab(),
                routes: [
                  GoRoute(
                    path: 'request/:id',
                    builder: (c, s) {
                      final id = s.pathParameters['id'] ?? '';
                      return ArtisanRequestDetailPage(requestId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'quotation',
                        builder: (c, s) {
                          final id = s.pathParameters['id'] ?? '';
                          return ArtisanQuotationFormPage(requestId: id);
                        },
                      ),
                      GoRoute(
                        path: 'materials',
                        builder: (c, s) {
                          final id = s.pathParameters['id'] ?? '';
                          return ArtisanMaterialsFormPage(requestId: id);
                        },
                      ),
                      GoRoute(
                        path: 'completion',
                        builder: (c, s) {
                          final id = s.pathParameters['id'] ?? '';
                          return ArtisanReportCompletionPage(requestId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/artisan-home/messages',
                builder: (c, s) => const ArtisanMessagesTab(),
                routes: [
                  GoRoute(
                    path: 'chat/:conversationId',
                    builder: (c, s) {
                      final serviceRequestId =
                          s.uri.queryParameters['serviceRequestId'] ?? '';
                      final counterpartyName =
                          s.uri.queryParameters['counterpartyName'] ??
                          'Customer';
                      return ConversationPage(
                        requestId: serviceRequestId,
                        artisanName: counterpartyName,
                        artisanTitle: null,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/artisan-home/earnings',
                builder: (c, s) => const ArtisanEarningsTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/artisan-home/profile',
                builder: (c, s) => const ArtisanProfileTab(),
                routes: [
                  GoRoute(
                    path: 'verification',
                    builder: (c, s) => const ArtisanVerificationPage(),
                    routes: [
                      GoRoute(
                        path: 'identity',
                        builder: (c, s) => const ArtisanIdentityFormPage(),
                      ),
                      GoRoute(
                        path: 'identity/document',
                        builder: (c, s) => const ArtisanIdDocumentPage(),
                      ),
                      GoRoute(
                        path: 'identity/selfie',
                        builder: (c, s) => const ArtisanSelfieCapturePage(),
                      ),
                      GoRoute(
                        path: 'professional',
                        builder: (c, s) =>
                            const ArtisanProfessionalReviewPage(),
                      ),
                      GoRoute(
                        path: 'documents',
                        builder: (c, s) =>
                            const ArtisanSupportingDocumentsPage(),
                      ),
                      GoRoute(
                        path: 'review',
                        builder: (c, s) => const ArtisanSubmissionReviewPage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (c, s) => const ArtisanProfileEditorPage(),
                  ),
                  GoRoute(
                    path: 'offerings',
                    builder: (c, s) => const ArtisanServiceOfferingsPage(),
                  ),
                  GoRoute(
                    path: 'availability',
                    builder: (c, s) => const ArtisanAvailabilityPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/artisan/requests/:id/quotation',
        builder: (c, s) {
          final id = s.pathParameters['id'] ?? '';
          return ArtisanQuotationFormPage(requestId: id);
        },
      ),
      GoRoute(
        path: '/artisan/requests/:id/materials',
        builder: (c, s) {
          final id = s.pathParameters['id'] ?? '';
          return ArtisanMaterialsFormPage(requestId: id);
        },
      ),
      GoRoute(
        path: '/artisan/requests/:id/completion',
        builder: (c, s) {
          final id = s.pathParameters['id'] ?? '';
          return ArtisanReportCompletionPage(requestId: id);
        },
      ),

      // ================================================================
      // Service catalog (guest accessible) and request lifecycle
      // ================================================================
      GoRoute(
        path: '/service-categories',
        builder: (c, s) => const ServiceCategoriesPage(),
      ),
      GoRoute(
        path: '/create-request',
        builder: (c, s) {
          final category = s.uri.queryParameters['category'] ?? '';
          return CreateRequestPage(initialCategory: category);
        },
      ),
      GoRoute(
        path: '/request-success',
        builder: (c, s) {
          final requestId = s.uri.queryParameters['requestId'] ?? '';
          final aiAssist = s.uri.queryParameters['aiAssist'] == 'true';
          return RequestSuccessPage(
            requestId: requestId,
            aiAssistEnabled: aiAssist,
          );
        },
      ),
      GoRoute(
        path: '/service-request/:id',
        builder: (c, s) {
          final id = s.pathParameters['id'] ?? '';
          return RequestTrackingPage(requestId: id);
        },
      ),
      GoRoute(
        path: '/service-request/:id/artisans',
        builder: (c, s) {
          final id = s.pathParameters['id'] ?? '';
          return ArtisanSelectionPage(requestId: id);
        },
      ),
      GoRoute(
        path: '/service-request/:id/artisans/:artisanId',
        builder: (c, s) {
          final id = s.pathParameters['id'] ?? '';
          final artisanId = s.pathParameters['artisanId'] ?? '';
          return ArtisanProfilePage(requestId: id, artisanId: artisanId);
        },
      ),
      GoRoute(
        path: '/service-request/:id/sent',
        builder: (c, s) {
          final id = s.pathParameters['id'] ?? '';
          final artisanName = s.uri.queryParameters['artisanName'] ?? '';
          return RequestSentPage(requestId: id, artisanName: artisanName);
        },
      ),
      GoRoute(
        path: '/service-request/:id/conversation',
        builder: (c, s) {
          final id = s.pathParameters['id'] ?? '';
          final artisanName = s.uri.queryParameters['artisanName'] ?? 'Artisan';
          final artisanTitle = s.uri.queryParameters['artisanTitle'];
          return ConversationPage(
            requestId: id,
            artisanName: artisanName,
            artisanTitle: artisanTitle,
          );
        },
      ),
      GoRoute(
        path: '/service-request/:id/review',
        builder: (c, s) {
          final id = s.pathParameters['id'] ?? '';
          final artisanName = s.uri.queryParameters['artisanName'] ?? 'Artisan';
          final artisanTitle = s.uri.queryParameters['artisanTitle'] ?? '';
          return LeaveReviewPage(
            requestId: id,
            artisanName: artisanName,
            artisanTitle: artisanTitle,
          );
        },
      ),
      GoRoute(
        path: '/service-request/:id/dispute',
        builder: (c, s) {
          final id = s.pathParameters['id'] ?? '';
          final serviceName = s.uri.queryParameters['serviceName'] ?? 'Service';
          final locationLabel = s.uri.queryParameters['locationLabel'] ?? '';
          return ReportIssuePage(
            requestId: id,
            serviceName: serviceName,
            locationLabel: locationLabel,
          );
        },
      ),
      GoRoute(
        path: '/artisans/:artisanId',
        builder: (c, s) {
          final artisanId = s.pathParameters['artisanId'] ?? '';
          final requestId = s.uri.queryParameters['requestId'] ?? '';
          return ArtisanPublicProfilePage(
            requestId: requestId,
            artisanId: artisanId,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShellPage(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            redirect: (context, state) => '/admin/dashboard',
          ),
          GoRoute(
            path: '/admin/dashboard',
            builder: (c, s) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (c, s) => const AdminUsersPage(),
          ),
          GoRoute(
            path: '/admin/verification',
            builder: (c, s) => const AdminVerificationPage(),
          ),
          GoRoute(
            path: '/admin/service-categories',
            builder: (c, s) => const AdminCategoriesPage(),
          ),
          GoRoute(
            path: '/admin/services',
            builder: (c, s) => const AdminServicesPage(),
          ),
          GoRoute(
            path: '/admin/service-requests',
            builder: (c, s) => const AdminServiceRequestsPage(),
          ),
          GoRoute(
            path: '/admin/audit-logs',
            builder: (c, s) => const AdminAuditLogsPage(),
          ),
          GoRoute(
            path: '/admin/payments',
            builder: (c, s) => const AdminPaymentsPage(),
          ),
          GoRoute(
            path: '/admin/payouts',
            builder: (c, s) => const AdminPayoutsPage(),
          ),
          GoRoute(
            path: '/admin/disputes',
            builder: (c, s) => const AdminDisputesPage(),
          ),
          GoRoute(
            path: '/admin/reviews',
            builder: (c, s) => const AdminComingSoonPage(title: 'Reviews'),
          ),
          GoRoute(
            path: '/admin/ai-intelligence',
            builder: (c, s) =>
                const AdminComingSoonPage(title: 'AI Intelligence'),
          ),
          GoRoute(
            path: '/admin/notifications',
            builder: (c, s) =>
                const AdminComingSoonPage(title: 'Notifications'),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (c, s) => const AdminComingSoonPage(title: 'Reports'),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (c, s) => const AdminPlatformSettingsPage(),
          ),
        ],
      ),
    ],
  );
});

/// The detail sub-routes for a service request. Nested under both the
/// Home and Requests branches so that pushing the detail keeps the
/// user on the tab they came from.
List<RouteBase> _serviceRequestRoutes() {
  return [
    GoRoute(
      path: 'request/:id',
      builder: (c, s) {
        final id = s.pathParameters['id'] ?? '';
        return RequestTrackingPage(requestId: id);
      },
      routes: [
        GoRoute(
          path: 'conversation',
          builder: (c, s) {
            final id = s.pathParameters['id'] ?? '';
            final artisanName =
                s.uri.queryParameters['artisanName'] ?? 'Artisan';
            final artisanTitle = s.uri.queryParameters['artisanTitle'];
            return ConversationPage(
              requestId: id,
              artisanName: artisanName,
              artisanTitle: artisanTitle,
            );
          },
        ),
        GoRoute(
          path: 'review',
          builder: (c, s) {
            final id = s.pathParameters['id'] ?? '';
            final artisanName =
                s.uri.queryParameters['artisanName'] ?? 'Artisan';
            final artisanTitle = s.uri.queryParameters['artisanTitle'] ?? '';
            return LeaveReviewPage(
              requestId: id,
              artisanName: artisanName,
              artisanTitle: artisanTitle,
            );
          },
        ),
        GoRoute(
          path: 'dispute',
          builder: (c, s) {
            final id = s.pathParameters['id'] ?? '';
            final serviceName =
                s.uri.queryParameters['serviceName'] ?? 'Service';
            final locationLabel = s.uri.queryParameters['locationLabel'] ?? '';
            return ReportIssuePage(
              requestId: id,
              serviceName: serviceName,
              locationLabel: locationLabel,
            );
          },
        ),
        // The artisan selection flow stays nested here too.
        GoRoute(
          path: 'artisans',
          builder: (c, s) {
            final id = s.pathParameters['id'] ?? '';
            return ArtisanSelectionPage(requestId: id);
          },
          routes: [
            GoRoute(
              path: ':artisanId',
              builder: (c, s) {
                final id = s.pathParameters['id'] ?? '';
                final artisanId = s.pathParameters['artisanId'] ?? '';
                return ArtisanProfilePage(requestId: id, artisanId: artisanId);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'sent',
          builder: (c, s) {
            final id = s.pathParameters['id'] ?? '';
            final artisanName = s.uri.queryParameters['artisanName'] ?? '';
            return RequestSentPage(requestId: id, artisanName: artisanName);
          },
        ),
      ],
    ),
  ];
}
