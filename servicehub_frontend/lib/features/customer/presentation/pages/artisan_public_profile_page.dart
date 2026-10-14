import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/artisan_summary.dart';
import '../providers/artisan_selection_providers.dart';
import '../widgets/artisan_avatar.dart';
import '../widgets/artisan_chip.dart';

/// A read-only artisan profile that renders regardless of request state.
///
/// This is the route reached from any "View Artisan Profile" CTA in the
/// tracking views. It fetches the artisan via the eligible-artisans
/// endpoint for the given request, then picks the matching artisan.
class ArtisanPublicProfilePage extends ConsumerWidget {
  const ArtisanPublicProfilePage({
    super.key,
    required this.requestId,
    required this.artisanId,
  });

  final String requestId;
  final String artisanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eligibleArtisansProvider(requestId));

    return Scaffold(
      backgroundColor: AppColors.cardLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
        data: (data) {
          final artisan = data.artisans.firstWhere(
            (a) => a.id == artisanId,
            orElse: () => data.artisans.first,
          );
          return _Body(artisan: artisan);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.artisan});

  final ArtisanSummary artisan;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          Center(
            child: ArtisanAvatar(
              artisan: artisan,
              size: 120,
              showVerifiedBadge: false,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            artisan.name,
            textAlign: TextAlign.center,
            style: AppTypography.h1.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            artisan.professionalTitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                artisan.ratingAverage.toStringAsFixed(1),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${artisan.reviewCount})',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '· ${artisan.experienceYears} yrs',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              const ArtisanChip(
                label: 'Verified',
                tone: ArtisanChipTone.success,
                icon: Icons.verified,
              ),
              if (artisan.respondsFast)
                const ArtisanChip(
                  label: 'Responds fast',
                  tone: ArtisanChipTone.success,
                  icon: Icons.bolt,
                ),
              if (artisan.serviceAreas.isNotEmpty)
                ArtisanChip(
                  label: artisan.serviceAreas
                      .map((a) => a.city)
                      .join(' · '),
                  tone: ArtisanChipTone.neutral,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          _SectionTitle(text: 'About'),
          Text(
            artisan.professionalDescription.isNotEmpty
                ? artisan.professionalDescription
                : artisan.bio,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(text: 'Availability'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _availabilityChips(artisan),
          ),
        ],
      ),
    );
  }

  List<Widget> _availabilityChips(ArtisanSummary artisan) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return List.generate(7, (i) {
      final isAvailable = artisan.availability[days[i]] != null;
      return Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isAvailable
              ? AppColors.cream.withValues(alpha: 0.4)
              : AppColors.cardLight,
          borderRadius: AppRadii.borderLg,
          border: Border.all(
            color: isAvailable ? AppColors.primary : AppColors.borderLight,
            width: isAvailable ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              labels[i],
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Icon(
              isAvailable ? Icons.check : Icons.remove,
              size: 13,
              color: isAvailable
                  ? AppColors.primary
                  : AppColors.textMuted,
            ),
          ],
        ),
      );
    });
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}