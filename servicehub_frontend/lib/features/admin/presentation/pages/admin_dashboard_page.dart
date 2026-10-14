import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../data/repositories/admin_dashboard_repository.dart';
import '../providers/admin_dashboard_providers.dart';
import '../widgets/dashboard/activity_timeline.dart';
import '../widgets/dashboard/metric_card.dart';
import '../widgets/dashboard/revenue_chart.dart';
import '../widgets/dashboard/review_queue_table.dart';
import '../widgets/dashboard/status_donut.dart';
import '../widgets/dashboard/welcome_banner.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminDashboardProvider);

    // Show cached data while refreshing; only show the spinner on the
    // very first load.
    final data = async.valueOrNull;
    final isLoadingFirstTime = async.isLoading && data == null;
    final hasError = async.hasError && data == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _pageHeader(ref),
          const SizedBox(height: 24),
          if (isLoadingFirstTime)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 120),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (hasError)
            _ErrorView(
              message: async.error.toString(),
              onRetry: () => ref.invalidate(adminDashboardProvider),
            )
          else if (data != null) ...[
            _welcomeBanner(context, ref, data),
            const SizedBox(height: 24),
            _metricsRow(data),
            const SizedBox(height: 24),
            _chartsRow(data),
            const SizedBox(height: 24),
            _bottomRow(context, data),
          ],
        ],
      ),
    );
  }

  Widget _pageHeader(WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: AppTypography.h2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Overview of platform activity and pending actions',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(adminDashboardProvider),
          icon: const Icon(
            Icons.refresh,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _welcomeBanner(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardData data,
  ) {
    final user = ref.watch(authStateProvider).user;
    final greeting = _greetingForNow();

    final parts = <String>[];
    if (data.pendingVerifications > 0) {
      parts.add(
        '${data.pendingVerifications} pending verification${data.pendingVerifications == 1 ? '' : 's'}',
      );
    }
    if (data.disputesNeedingAttention > 0) {
      parts.add(
        '${data.disputesNeedingAttention} open dispute${data.disputesNeedingAttention == 1 ? '' : 's'}',
      );
    }
    final summary = parts.isEmpty
        ? 'All caught up. No pending actions require your attention.'
        : 'You have ${parts.join(' and ')} to review.';

    return WelcomeBanner(
      greeting: '$greeting, ${user?.firstName ?? 'Administrator'}',
      summary: summary,
      onGoToQueue: () => context.go('/admin/verification'),
    );
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _metricsRow(AdminDashboardData data) {
    final revenueDelta = data.revenueDeltaPercent;
    final revenueTone = revenueDelta >= 0
        ? MetricDeltaTone.positive
        : MetricDeltaTone.negative;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: MetricCard(
            icon: Icons.verified_user_outlined,
            label: 'Pending verifications',
            value: '${data.pendingVerifications}',
            delta: data.pendingVerifications == 0
                ? 'Nothing pending'
                : 'Needs review',
            deltaTone: data.pendingVerifications == 0
                ? MetricDeltaTone.positive
                : MetricDeltaTone.warning,
            sparklinePoints: const [
              0.55,
              0.62,
              0.58,
              0.7,
              0.66,
              0.78,
              0.82,
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: MetricCard(
            icon: Icons.assignment_outlined,
            label: 'Active requests',
            value: '${data.activeRequests}',
            delta: '${data.serviceRequestsTotal} total',
            deltaTone: MetricDeltaTone.positive,
            sparklinePoints: const [
              0.3,
              0.4,
              0.55,
              0.5,
              0.65,
              0.62,
              0.8,
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: MetricCard(
            icon: Icons.gavel_outlined,
            label: 'Open disputes',
            value: '${data.openDisputes}',
            delta: data.disputesNeedingAttention == 0
                ? 'All clear'
                : '${data.disputesNeedingAttention} need attention',
            deltaTone: data.disputesNeedingAttention == 0
                ? MetricDeltaTone.positive
                : MetricDeltaTone.negative,
            sparklinePoints: const [
              0.6,
              0.55,
              0.7,
              0.5,
              0.45,
              0.6,
              0.55,
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: MetricCard(
            icon: Icons.payments_outlined,
            label: 'Revenue this month',
            value: _formatXafCompact(data.revenueThisMonth),
            delta: data.revenueLastMonth == 0
                ? 'First month of data'
                : '${revenueDelta >= 0 ? '+' : ''}${revenueDelta.toStringAsFixed(1)}% vs last month',
            deltaTone: revenueTone,
            sparklinePoints: const [
              0.35,
              0.42,
              0.55,
              0.5,
              0.68,
              0.75,
              0.85,
            ],
          ),
        ),
      ],
    );
  }

  Widget _chartsRow(AdminDashboardData data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 8,
          child: RevenueChart(days: data.dailySeries),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: StatusDonut(
            segments: data.donutSegments,
            topServices: data.topServices,
          ),
        ),
      ],
    );
  }

  Widget _bottomRow(BuildContext context, AdminDashboardData data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 8,
          child: const ReviewQueueTable(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: ActivityTimeline(
            activity: data.recentActivity,
            onViewAll: () => context.go('/admin/audit-logs'),
          ),
        ),
      ],
    );
  }

  String _formatXafCompact(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '$amount';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}