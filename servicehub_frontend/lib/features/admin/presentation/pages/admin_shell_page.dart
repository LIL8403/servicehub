import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../providers/admin_dispute_providers.dart';
import '../providers/admin_verification_providers.dart';
import '../widgets/layout/admin_sidebar.dart';
import '../widgets/layout/admin_top_nav.dart';

class AdminShellPage extends ConsumerWidget {
  const AdminShellPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb) {
      return const _AdminDesktopOnlyScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1100) {
          return const _AdminNeedsMoreSpaceScreen();
        }

        final user = ref.watch(authStateProvider).user;
        final adminName = user?.fullName ?? 'Administrator';
        final adminEmail = user?.email ?? '';
        final currentPath = GoRouterState.of(context).uri.path;

        // Live counts for the sidebar badges.
        final pendingVerificationsAsync =
            ref.watch(pendingArtisansProvider);
        final disputesAsync = ref.watch(disputesListProvider);

        final verificationBadge =
            pendingVerificationsAsync.valueOrNull?.length;

        final disputesBadge = disputesAsync.valueOrNull?.where((d) {
          const active = {
            'opened',
            'under_review',
            'awaiting_information',
            'under_investigation',
            'pending_execution',
            'reconciliation_required',
          };
          return active.contains(d.status);
        }).length;

        return Scaffold(
          backgroundColor: AppColors.bgLight,
          body: Row(
            children: [
              AdminSidebar(
                currentPath: currentPath,
                onSignOut: () => _onSignOut(context, ref),
                verificationBadge: verificationBadge,
                disputesBadge: disputesBadge,
              ),
              Expanded(
                child: Column(
                  children: [
                    AdminTopNav(
                      adminName: adminName,
                      adminEmail: adminEmail,
                      currentPath: currentPath,
                    ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.5),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Sign out?',
          style: AppTypography.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'You will need to log in again to access the admin panel.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Sign out',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).logout();
    }
  }
}

class _AdminDesktopOnlyScreen extends StatelessWidget {
  const _AdminDesktopOnlyScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.desktop_windows_outlined,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Please use a desktop browser',
                textAlign: TextAlign.center,
                style: AppTypography.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'The ServiceHUB administrator panel is a web-only '
                'experience. Open it on a laptop or desktop to continue.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNeedsMoreSpaceScreen extends StatelessWidget {
  const _AdminNeedsMoreSpaceScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.open_in_full_outlined,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Please widen your browser window',
                textAlign: TextAlign.center,
                style: AppTypography.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: 420,
                child: Text(
                  'The ServiceHUB administrator panel is designed for '
                  'desktop screens. Drag the edge of your browser '
                  'window to make it wider, or maximize it, to '
                  'continue.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}