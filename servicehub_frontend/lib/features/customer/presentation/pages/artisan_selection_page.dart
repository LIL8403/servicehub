import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/artisan_summary.dart';
import '../../domain/models/eligible_artisans_response.dart';
import '../providers/artisan_selection_providers.dart';
import '../widgets/ai_recommended_card.dart';
import '../widgets/artisan_card.dart';

enum _SortOption { topRated, nearest, mostExperienced }

class ArtisanSelectionPage extends ConsumerStatefulWidget {
  const ArtisanSelectionPage({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<ArtisanSelectionPage> createState() =>
      _ArtisanSelectionPageState();
}

class _ArtisanSelectionPageState extends ConsumerState<ArtisanSelectionPage> {
  _SortOption _sort = _SortOption.topRated;
  bool _verifiedOnly = false;

  List<ArtisanSummary> _applySort(List<ArtisanSummary> input) {
    final list = List<ArtisanSummary>.from(input);
    switch (_sort) {
      case _SortOption.topRated:
        list.sort((a, b) => b.ratingAverage.compareTo(a.ratingAverage));
      case _SortOption.nearest:
        list.sort((a, b) =>
            (a.distanceKm ?? 9999).compareTo(b.distanceKm ?? 9999));
      case _SortOption.mostExperienced:
        list.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(eligibleArtisansProvider(widget.requestId));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.artisanSelectionTitle,
          style: AppTypography.h3.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(
            eligibleArtisansProvider(widget.requestId),
          ),
        ),
        data: (data) {
          if (data.artisans.isEmpty) {
            return _EmptyView(requestId: widget.requestId);
          }

          return _SelectionBody(
            data: data,
            sort: _sort,
            verifiedOnly: _verifiedOnly,
            onSortChanged: (s) => setState(() => _sort = s),
            onVerifiedChanged: (v) => setState(() => _verifiedOnly = v),
            applySort: _applySort,
          );
        },
      ),
    );
  }
}

class _SelectionBody extends StatelessWidget {
  const _SelectionBody({
    required this.data,
    required this.sort,
    required this.verifiedOnly,
    required this.onSortChanged,
    required this.onVerifiedChanged,
    required this.applySort,
  });

  final EligibleArtisansResponse data;
  final _SortOption sort;
  final bool verifiedOnly;
  final ValueChanged<_SortOption> onSortChanged;
  final ValueChanged<bool> onVerifiedChanged;
  final List<ArtisanSummary> Function(List<ArtisanSummary>) applySort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAiMode = data.hasAiRecommendations;

    // Build the list of cards for the scrollable area.
    final widgets = <Widget>[];

    if (isAiMode) {
      final ranked = data.rankedArtisans;
      final others = data.otherArtisans;

      widgets.add(_AiSectionHeader());

      for (var i = 0; i < ranked.length; i++) {
        final entry = ranked[i];
        widgets.add(
          AiRecommendedCard(
            artisan: entry.artisan,
            recommendation: entry.recommendation,
            onTap: () => context.push(
              '/service-request/${data.request.id}/artisans/${entry.artisan.id}',
            ),
          ),
        );
        if (i < ranked.length - 1) {
          widgets.add(const SizedBox(height: AppSpacing.sm + AppSpacing.xs));
        }
      }

      if (others.isNotEmpty) {
        widgets.add(const SizedBox(height: AppSpacing.lg));
        widgets.add(_OtherArtisansHeader(count: others.length));
        widgets.add(const SizedBox(height: AppSpacing.sm));

        final sortedOthers = applySort(others);
        for (var i = 0; i < sortedOthers.length; i++) {
          final a = sortedOthers[i];
          widgets.add(
            ArtisanCard(
              artisan: a,
              onTap: () => context.push(
                '/service-request/${data.request.id}/artisans/${a.id}',
              ),
            ),
          );
          if (i < sortedOthers.length - 1) {
            widgets.add(
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            );
          }
        }
      }
    } else {
      final sorted = applySort(data.artisans);
      for (var i = 0; i < sorted.length; i++) {
        final a = sorted[i];
        widgets.add(
          ArtisanCard(
            artisan: a,
            onTap: () => context.push(
              '/service-request/${data.request.id}/artisans/${a.id}',
            ),
          ),
        );
        if (i < sorted.length - 1) {
          widgets.add(
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          );
        }
      }
    }

    return Column(
      children: [
        _Breadcrumb(request: data.request, l10n: l10n),
        // Show the filter row only in non-AI mode. In AI mode the
        // rankings are authoritative; sorting would contradict them.
        if (!isAiMode)
          _FilterRow(
            sort: sort,
            verifiedOnly: verifiedOnly,
            onSortChanged: onSortChanged,
            onVerifiedChanged: onVerifiedChanged,
            l10n: l10n,
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: widgets,
          ),
        ),
      ],
    );
  }
}

class _AiSectionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 14,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            'AI-RECOMMENDED',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherArtisansHeader extends StatelessWidget {
  const _OtherArtisansHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Other available artisans',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '$count more',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.request, required this.l10n});

  final RequestSnapshot request;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final label = request.location?['label']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      color: AppColors.cardLight,
      child: Row(
        children: [
          const Icon(
            Icons.build_outlined,
            size: 15,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label.isEmpty
                  ? l10n.artisanSelectionTitle
                  : '${l10n.artisanSelectionBreadcrumbService} · $label',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.sort,
    required this.verifiedOnly,
    required this.onSortChanged,
    required this.onVerifiedChanged,
    required this.l10n,
  });

  final _SortOption sort;
  final bool verifiedOnly;
  final ValueChanged<_SortOption> onSortChanged;
  final ValueChanged<bool> onVerifiedChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardLight,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            _chip(
              label: l10n.artisanSortTopRated,
              active: sort == _SortOption.topRated,
              onTap: () => onSortChanged(_SortOption.topRated),
            ),
            const SizedBox(width: 8),
            _chip(
              label: l10n.artisanSortNearest,
              active: sort == _SortOption.nearest,
              onTap: () => onSortChanged(_SortOption.nearest),
            ),
            const SizedBox(width: 8),
            _chip(
              label: l10n.artisanSortMostExperienced,
              active: sort == _SortOption.mostExperienced,
              onTap: () => onSortChanged(_SortOption.mostExperienced),
            ),
            const SizedBox(width: 12),
            _chip(
              label: l10n.artisanFilterVerifiedOnly,
              active: verifiedOnly,
              icon: Icons.verified,
              onTap: () => onVerifiedChanged(!verifiedOnly),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.cardLight,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: active ? AppColors.textInverse : AppColors.secondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: active ? AppColors.textInverse : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.artisanSelectionEmptyTitle,
              style: AppTypography.h3.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.artisanSelectionEmptyBody,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: const StadiumBorder(),
                ),
                child: Text(l10n.artisanSelectionEmptyBack),
              ),
            ),
          ],
        ),
      ),
    );
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
            const Icon(
              Icons.error_outline,
              size: 56,
              color: AppColors.error,
            ),
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
                foregroundColor: AppColors.textInverse,
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