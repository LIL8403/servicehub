import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/enums/service_request_status.dart';
import '../../domain/models/artisan_directory_entry.dart';
import '../providers/artisan_directory_providers.dart';
import '../providers/my_requests_providers.dart';
import '../widgets/customer_search_bar.dart';
import '../widgets/featured_artisan_card.dart';
import '../widgets/quick_action_tile.dart';
import '../widgets/request_progress_stepper.dart';
import '../widgets/request_status_chip.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CustomerHomeTab extends ConsumerWidget {
  const CustomerHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final requestsAsync = ref.watch(myRequestsProvider);
    final artisansAsync = ref.watch(featuredArtisansProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myRequestsProvider);
            ref.invalidate(featuredArtisansProvider);
            await Future.wait([
              ref.read(myRequestsProvider.future),
              ref.read(featuredArtisansProvider.future),
            ]);
          },
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              _Greeting(firstName: user?.firstName ?? 'there'),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: CustomerSearchBar(
                  hint: 'Search services or artisans',
                  onSubmitted: (value) {
                    if (value.trim().isEmpty) return;
                    context.go(
                      '/customer-home/discover?q=${Uri.encodeComponent(value.trim())}',
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _BookServiceCta(
                  onTap: () => context.go('/service-categories'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              requestsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: _ErrorCard(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(myRequestsProvider),
                  ),
                ),
                data: (requests) {
                  final active = requests
                      .where((r) => _isActive(r.status))
                      .toList();
                  if (active.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: _NoActiveRequestCard(
                        onViewAll: () => context.go('/customer-home/requests'),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: _CurrentRequestCard(
                      item: active.first,
                      onViewAll: () => context.go('/customer-home/requests'),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _SectionTitle(title: 'Quick actions'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm + AppSpacing.xs,
                  crossAxisSpacing: AppSpacing.sm + AppSpacing.xs,
                  childAspectRatio: 0.95,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    QuickActionTile(
                      icon: LucideIcons.clipboardList,
                      label: 'My requests',
                      subtitle: 'Track your bookings',
                      accent: QuickActionAccent.primary,
                      onTap: () => context.go('/customer-home/requests'),
                    ),
                    QuickActionTile(
                      icon: LucideIcons.messageCircle,
                      label: 'Messages',
                      subtitle: 'Chat with artisans',
                      accent: QuickActionAccent.secondary,
                      onTap: () => context.go('/customer-home/messages'),
                    ),
                    QuickActionTile(
                      icon: LucideIcons.compass,
                      label: 'Discover',
                      subtitle: 'Find services',
                      accent: QuickActionAccent.primary,
                      onTap: () => context.go('/customer-home/discover'),
                    ),
                    QuickActionTile(
                      icon: LucideIcons.user,
                      label: 'Profile',
                      subtitle: 'Account & settings',
                      accent: QuickActionAccent.primary,
                      onTap: () => context.go('/customer-home/profile'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              artisansAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (artisans) {
                  if (artisans.isEmpty) return const SizedBox.shrink();
                  return _RecommendedSection(artisans: artisans);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isActive(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.completed:
      case ServiceRequestStatus.cancelled:
        return false;
      default:
        return true;
    }
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _prefix(),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  firstName,
                  style: AppTypography.h2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cream.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              firstName.isNotEmpty ? firstName[0].toUpperCase() : 'C',
              style: AppTypography.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _prefix() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _BookServiceCta extends StatelessWidget {
  const _BookServiceCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.borderLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add,
                  color: AppColors.textInverse,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book a service',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Browse categories and find verified artisans',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textInverse.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textInverse,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentRequestCard extends StatelessWidget {
  const _CurrentRequestCard({required this.item, required this.onViewAll});

  final RequestListItem item;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current request',
              style: AppTypography.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'See all',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: AppColors.cardLight,
          borderRadius: AppRadii.borderLg,
          child: InkWell(
            borderRadius: AppRadii.borderLg,
            onTap: () => context.push('/customer-home/request/${item.id}'),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: AppRadii.borderLg,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.serviceName,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      RequestStatusChip(status: item.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  RequestProgressStepper(status: item.status),
                  const SizedBox(height: AppSpacing.sm + 2),
                  Container(
                    padding: const EdgeInsets.only(top: AppSpacing.sm + 2),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 15,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${item.locationLabel} · Ref: ${item.shortRef}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoActiveRequestCard extends StatelessWidget {
  const _NoActiveRequestCard({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No active requests',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start by tapping "Book a service" above.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onViewAll,
            child: Text(
              'See all requests',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.h4.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _RecommendedSection extends ConsumerWidget {
  const _RecommendedSection({required this.artisans});

  final List<ArtisanDirectoryEntry> artisans;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Compute distances client-side using the cached current location
    // when available. Falls back to Yaounde when not.
    ref.watch(currentLocationProvider).valueOrNull;
    ref.watch(locationServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended for you',
                style: AppTypography.h4.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/customer-home/discover'),
                child: Text(
                  'See all',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: artisans.length > 8 ? 8 : artisans.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            itemBuilder: (context, index) {
              final artisan = artisans[index];
              return FeaturedArtisanCard(
                artisan: artisan,
                onTap: () => context.push('/artisans/${artisan.id}?requestId='),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorTint,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 32, color: AppColors.error),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: const StadiumBorder(),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
