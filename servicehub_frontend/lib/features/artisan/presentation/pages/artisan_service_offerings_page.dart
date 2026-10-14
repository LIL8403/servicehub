import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../../customer/presentation/providers/service_catalog_providers.dart';
import '../../domain/models/service_offering.dart';
import '../providers/artisan_service_offering_providers.dart';
import '../widgets/offerings/offering_form_sheet.dart';
import '../widgets/offerings/offering_row.dart';

class ArtisanServiceOfferingsPage extends ConsumerWidget {
  const ArtisanServiceOfferingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringsAsync = ref.watch(artisanServiceOfferingsProvider);
    final catalogAsync = ref.watch(serviceCatalogProvider);
    final action = ref.watch(offeringActionProvider);

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
          'Service offerings',
          style: AppTypography.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(artisanServiceOfferingsProvider);
          await ref.read(artisanServiceOfferingsProvider.future);
        },
        child: offeringsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorView(
            message: err.toString(),
            onRetry: () => ref.invalidate(artisanServiceOfferingsProvider),
          ),
          data: (offerings) {
            final catalog = catalogAsync.valueOrNull ?? const [];

            // Group by category slug. Unknown services fall back to
            // "Other" so nothing is lost if the catalogue drifts.
            final grouped = <String, List<ServiceOffering>>{};
            for (final o in offerings) {
              final cat = _categoryLabel(catalog, o.serviceId);
              grouped.putIfAbsent(cat, () => []).add(o);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                _Intro(),
                const SizedBox(height: AppSpacing.md),
                if (action.errorMessage != null) ...[
                  _ErrorBanner(message: action.errorMessage!),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (offerings.isEmpty)
                  _Empty()
                else
                  for (final entry in grouped.entries) ...[
                    _CategoryHeader(title: entry.key),
                    _CategoryCard(
                      children: [
                        for (var i = 0; i < entry.value.length; i++) ...[
                          OfferingRow(
                            offering: entry.value[i],
                            serviceName: _serviceName(
                              catalog,
                              entry.value[i].serviceId,
                            ),
                            categoryName: entry.key,
                            onEdit: () => _openEdit(
                              context,
                              ref,
                              catalog,
                              entry.value[i],
                            ),
                            onToggleActive: () => _toggle(ref, entry.value[i]),
                            onRemove: () =>
                                _confirmRemove(context, ref, entry.value[i]),
                          ),
                          if (i < entry.value.length - 1)
                            const Divider(
                              height: 1,
                              color: AppColors.borderLight,
                            ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _openAdd(context, ref, catalog, offerings),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add a service'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _serviceName(List<ServiceRef> catalog, String serviceId) {
    for (final s in catalog) {
      if (s.id == serviceId) return s.name;
    }
    return 'Unknown service';
  }

  String _categoryLabel(List<ServiceRef> catalog, String serviceId) {
    for (final s in catalog) {
      if (s.id == serviceId) {
        return s.categorySlug.isEmpty ? 'Other' : _titleCase(s.categorySlug);
      }
    }
    return 'Other';
  }

  String _titleCase(String slug) {
    return slug
        .split('-')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Future<void> _openAdd(
    BuildContext context,
    WidgetRef ref,
    List<ServiceRef> catalog,
    List<ServiceOffering> existing,
  ) async {
    final already = existing.map((o) => o.serviceId).toSet();
    final options = catalog
        .where((s) => !already.contains(s.id))
        .map(
          (s) => OfferingServiceOption(
            id: s.id,
            name: s.name,
            categoryName: s.categorySlug.isEmpty
                ? 'Other'
                : _titleCase(s.categorySlug),
          ),
        )
        .toList();

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already offer every service in the catalogue.'),
        ),
      );
      return;
    }

    final result = await showOfferingFormSheet(context, services: options);
    if (result == null) return;
    if (!context.mounted) return;

    final ok = await ref
        .read(offeringActionProvider.notifier)
        .add(
          serviceId: result.serviceId,
          startingPrice: result.startingPrice,
          description: result.description,
        );

    if (!ok) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Service added.')));
  }

  Future<void> _openEdit(
    BuildContext context,
    WidgetRef ref,
    List<ServiceRef> catalog,
    ServiceOffering offering,
  ) async {
    final current = catalog
        .where((s) => s.id == offering.serviceId)
        .map(
          (s) => OfferingServiceOption(
            id: s.id,
            name: s.name,
            categoryName: s.categorySlug.isEmpty
                ? 'Other'
                : _titleCase(s.categorySlug),
          ),
        )
        .toList();

    final result = await showOfferingFormSheet(
      context,
      services: current,
      initialServiceId: offering.serviceId,
      initialStartingPrice: offering.startingPrice,
      initialDescription: offering.description,
      isEditing: true,
    );
    if (result == null) return;
    if (!context.mounted) return;

    final ok = await ref
        .read(offeringActionProvider.notifier)
        .update(
          offering.offeringId,
          startingPrice: result.startingPrice,
          description: result.description,
          clearStartingPrice: result.startingPrice == null,
          clearDescription:
              result.description == null || result.description!.isEmpty,
        );

    if (!ok) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Offering updated.')));
  }

  Future<void> _toggle(WidgetRef ref, ServiceOffering offering) async {
    await ref
        .read(offeringActionProvider.notifier)
        .update(offering.offeringId, isActive: !offering.isActive);
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    ServiceOffering offering,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
        title: Text(
          'Remove this service?',
          style: AppTypography.h4.copyWith(color: AppColors.primary),
        ),
        content: Text(
          'Customers will no longer be able to hire you for this '
          'service. Any requests already in flight are unaffected.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Remove',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await ref
        .read(offeringActionProvider.notifier)
        .remove(offering.offeringId);

    if (!ok) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Service removed.')));
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _Intro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.5),
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'These are the services customers can hire you for. '
              'Pause one to hide it temporarily without losing the entry.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(children: children),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.handyman_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No services yet',
            style: AppTypography.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add at least one service so customers can hire you.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
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
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.errorTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
