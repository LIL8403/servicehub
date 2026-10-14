import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/artisan_summary.dart';
import '../providers/artisan_selection_providers.dart';
import '../widgets/artisan_avatar.dart';
import '../widgets/artisan_chip.dart';
import '../widgets/selection_confirmation_sheet.dart';

class ArtisanProfilePage extends ConsumerStatefulWidget {
  const ArtisanProfilePage({
    super.key,
    required this.requestId,
    required this.artisanId,
  });

  final String requestId;
  final String artisanId;

  @override
  ConsumerState<ArtisanProfilePage> createState() => _ArtisanProfilePageState();
}

class _ArtisanProfilePageState extends ConsumerState<ArtisanProfilePage> {
  bool _submitting = false;

  Future<void> _onSelect(ArtisanSummary artisan) async {
    final l10n = AppLocalizations.of(context);
    // Pull real values from the request snapshot returned by the endpoint
    final request = ref
        .read(eligibleArtisansProvider(widget.requestId))
        .valueOrNull
        ?.request;

    final locationLabel = request?.location?['label']?.toString() ?? '';

    final date = request?.preferredSchedule?['date']?.toString();
    final window = request?.preferredSchedule?['window']?.toString();
    final preferredDateLabel = date == null
        ? (window ?? '')
        : '$date · ${window ?? ''}'.trim();

    final confirmed = await showSelectionConfirmationSheet(
      context,
      artisan: artisan,
      serviceTitle: l10n.artisanSelectionBreadcrumbService,
      locationLabel: locationLabel,
      preferredDateLabel: preferredDateLabel,
      isSubmitting: _submitting,
    );

    if (!confirmed || !mounted) return;

    setState(() => _submitting = true);

    final success = await ref
        .read(selectionProvider.notifier)
        .selectArtisan(requestId: widget.requestId, artisanId: artisan.id);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      context.go('/service-request/${widget.requestId}/sent');
    } else {
      final err =
          ref.read(selectionProvider).errorMessage ??
          'Failed to select artisan.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(eligibleArtisansProvider(widget.requestId));

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
        error: (e, _) => Center(child: Text(e.toString())),
        data: (data) {
          final artisan = data.artisans.firstWhere(
            (a) => a.id == widget.artisanId,
            orElse: () => data.artisans.first,
          );

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
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
                        style: AppTypography.h1.copyWith(
                          color: AppColors.primary,
                        ),
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
                            ArtisanChip(
                              label: l10n.artisanChipRespondsFast,
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
                      _sectionTitle(l10n.artisanProfileAbout),
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
                      _sectionTitle(l10n.artisanProfileAvailability),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _availabilityChips(artisan),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _sectionTitle(l10n.artisanProfilePrice),
                      Text(
                        l10n.artisanProfilePriceNote,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.cardLight,
                  border: Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting
                            ? null
                            : () => _onSelect(artisan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textInverse,
                          shape: const StadiumBorder(),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.textInverse,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l10n.artisanProfileSelect,
                                    style: AppTypography.bodyLarge.copyWith(
                                      color: AppColors.textInverse,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 20,
                                    color: AppColors.textInverse,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        l10n.artisanProfileBackToList,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
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
              color: isAvailable ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      );
    });
  }
}
