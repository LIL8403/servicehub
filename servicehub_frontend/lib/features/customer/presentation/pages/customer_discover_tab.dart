import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mhj_maps/mhj_maps.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../core/location/location_service.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/artisan_directory_entry.dart';
import '../../domain/models/service_category.dart';
import '../providers/artisan_directory_providers.dart';
import '../widgets/compact_artisan_row.dart';
import '../widgets/customer_search_bar.dart';
import '../widgets/featured_artisan_card.dart';
import '../widgets/service_category_grid_card.dart';
import '../widgets/service_picker_sheet.dart';

class CustomerDiscoverTab extends ConsumerStatefulWidget {
  const CustomerDiscoverTab({super.key});

  @override
  ConsumerState<CustomerDiscoverTab> createState() =>
      _CustomerDiscoverTabState();
}

class _CustomerDiscoverTabState extends ConsumerState<CustomerDiscoverTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(currentLocationProvider);
    final locationService = ref.watch(locationServiceProvider);
    final availabilityAsync = ref.watch(locationAvailabilityProvider);

    final query = (
      serviceId: null,
      search: _search.isEmpty ? null : _search,
      latitude: null,
      longitude: null,
      limit: 30,
    );
    final artisansAsync = ref.watch(artisanDirectoryProvider(query));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Discover',
          style: AppTypography.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.primary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentLocationProvider);
          ref.invalidate(artisanDirectoryProvider);
          await Future.wait([
            ref.read(currentLocationProvider.future),
            ref.read(artisanDirectoryProvider(query).future),
          ]);
        },
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: CustomerSearchBar(
                hint: 'Search services or artisans',
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _SectionHeader(title: 'Service categories'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm + AppSpacing.xs,
                crossAxisSpacing: AppSpacing.sm + AppSpacing.xs,
                childAspectRatio: 1.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: ServiceCategories.all.map((c) {
                  return ServiceCategoryGridCard(
                    icon: _iconForSlug(c.slug),
                    title: _labelForSlug(context, c.slug),
                    subtitle: _subtitleForSlug(c.slug),
                    onTap: () => _openCategory(context, c),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            artisansAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _ErrorCard(
                  message: err.toString(),
                  onRetry: () =>
                      ref.invalidate(artisanDirectoryProvider(query)),
                ),
              ),
              data: (artisans) {
                if (artisans.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: _EmptyArtisans(),
                  );
                }

                // Featured = top-rated, first 8.
                final featured = [...artisans]
                  ..sort((a, b) => b.ratingAverage.compareTo(a.ratingAverage));
                final top = featured.take(8).toList();

                // Near-you = sorted by straight-line distance from the
                // device location, when available.
                final origin = locationAsync.valueOrNull;
                final near = origin == null
                    ? artisans.take(5).toList()
                    : ([...artisans]..sort((a, b) {
                            final da = _distance(locationService, origin, a);
                            final db = _distance(locationService, origin, b);
                            return (da ?? 99999).compareTo(db ?? 99999);
                          }))
                          .take(5)
                          .toList();

                final gpsAvailable =
                    availabilityAsync.valueOrNull ==
                    LocationAvailability.granted;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: _SectionHeader(title: 'Featured artisans'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 210,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        itemCount: top.length,
                        separatorBuilder: (_, _) => const SizedBox(
                          width: AppSpacing.sm + AppSpacing.xs,
                        ),
                        itemBuilder: (context, index) {
                          final artisan = top[index];
                          return FeaturedArtisanCard(
                            width: 200,
                            artisan: artisan,
                            onTap: () =>
                                _showArtisanPlaceholder(context, artisan),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Near you',
                            style: AppTypography.h4.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: gpsAvailable
                                  ? AppColors.successTint
                                  : AppColors.cream,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              gpsAvailable ? 'GPS Active' : 'Using Yaoundé',
                              style: AppTypography.caption.copyWith(
                                color: gpsAvailable
                                    ? AppColors.success
                                    : AppColors.secondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: AppRadii.borderLg,
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadii.borderLg,
                        child: Column(
                          children: [
                            for (var i = 0; i < near.length; i++) ...[
                              CompactArtisanRow(
                                artisan: near[i],
                                distanceLabel: origin == null
                                    ? null
                                    : _distanceLabel(
                                        locationService,
                                        origin,
                                        near[i],
                                      ),
                                locationLabel: near[i].serviceAreas.isNotEmpty
                                    ? near[i].serviceAreas.first
                                    : null,
                                onTap: () =>
                                    _showArtisanPlaceholder(context, near[i]),
                              ),
                              if (i < near.length - 1)
                                const Divider(
                                  height: 1,
                                  color: AppColors.borderLight,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: _BrowseByLocationCard(
                        cityLabel: gpsAvailable ? 'your area' : 'Yaoundé',
                        origin: origin ?? LocationService.fallbackYaounde,
                        onTap: () =>
                            context.push('/customer-home/discover/map'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  double? _distance(
    LocationService service,
    GeoPoint origin,
    ArtisanDirectoryEntry artisan,
  ) {
    if (artisan.latitude == null || artisan.longitude == null) return null;
    return service.distanceKm(
      origin,
      GeoPoint(latitude: artisan.latitude!, longitude: artisan.longitude!),
    );
  }

  String? _distanceLabel(
    LocationService service,
    GeoPoint origin,
    ArtisanDirectoryEntry artisan,
  ) {
    final km = _distance(service, origin, artisan);
    if (km == null) return null;
    return '${km.toStringAsFixed(1)} km away';
  }

  void _showArtisanPlaceholder(
    BuildContext context,
    ArtisanDirectoryEntry artisan,
  ) {
    // The Discover tab list still routes to the artisan's public
    // profile, not the map. The map is reached via the "Explore
    // artisans in [city]" card below.
    context.push('/artisans/${artisan.id}?requestId=');
  }

  Future<void> _openCategory(
    BuildContext context,
    ServiceCategory category,
  ) async {
    final service = await showServicePickerSheet(
      context,
      categorySlug: category.slug,
    );
    if (service == null) return;
    if (!context.mounted) return;

    context.go(
      '/create-request'
      '?category=${category.id}'
      '&serviceId=${service.id}',
    );
  }

  IconData _iconForSlug(String slug) {
    switch (slug) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.bolt;
      case 'carpentry':
        return Icons.carpenter;
      case 'painting':
        return Icons.format_paint;
      case 'masonry':
        return Icons.handyman;
      case 'mechanics':
        return Icons.settings;
      default:
        return Icons.category;
    }
  }

  String _labelForSlug(BuildContext context, String slug) {
    switch (slug) {
      case 'plumbing':
        return 'Plumbing';
      case 'electrical':
        return 'Electrical';
      case 'carpentry':
        return 'Carpentry';
      case 'painting':
        return 'Painting';
      case 'masonry':
        return 'Masonry';
      case 'mechanics':
        return 'Mechanics';
      default:
        return slug;
    }
  }

  String _subtitleForSlug(String slug) {
    switch (slug) {
      case 'plumbing':
        return 'Leaks, pipes, drainage';
      case 'electrical':
        return 'Wiring, panels, lights';
      case 'carpentry':
        return 'Furniture, doors, locks';
      case 'painting':
        return 'Interior, exterior coats';
      case 'masonry':
        return 'Tiling, brickwork, repair';
      case 'mechanics':
        return 'Generators, AC, pumps';
      default:
        return '';
    }
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'See all',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BrowseByLocationCard extends StatelessWidget {
  const _BrowseByLocationCard({
    required this.cityLabel,
    required this.origin,
    required this.onTap,
  });

  final String cityLabel;
  final GeoPoint origin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardLight,
      borderRadius: AppRadii.borderLg,
      child: InkWell(
        borderRadius: AppRadii.borderLg,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadii.borderLg,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.lg),
                ),
                child: SizedBox(
                  height: 120,
                  child: MhjMapsMap(
                    center: MhjMapsLatLng(
                      lat: origin.latitude,
                      lng: origin.longitude,
                    ),
                    zoom: 12,
                    tileProvider: MhjMapsTileProvider.openStreetMap,
                    interactive: false,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Explore artisans in $cityLabel',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Messa, Bastos, Biyem-Assi, Omnisports & more',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyArtisans extends StatelessWidget {
  const _EmptyArtisans();

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
            Icons.people_outline,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No artisans found',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search or browse by service.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
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
