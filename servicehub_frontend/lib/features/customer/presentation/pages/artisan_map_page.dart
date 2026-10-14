import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mhj_maps/mhj_maps.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../domain/models/artisan_directory_entry.dart';
import '../providers/artisan_map_providers.dart';
import '../widgets/map/artisan_map_bottom_sheet.dart';
import '../widgets/map/artisan_map_pin.dart';
import '../widgets/map/map_top_bar.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:flutter_map/flutter_map.dart'
    show CameraFit, Marker, MarkerLayer, LatLngBounds;

class ArtisanMapPage extends ConsumerStatefulWidget {
  const ArtisanMapPage({super.key});

  @override
  ConsumerState<ArtisanMapPage> createState() => _ArtisanMapPageState();
}

class _ArtisanMapPageState extends ConsumerState<ArtisanMapPage>
    with SingleTickerProviderStateMixin {
  MhjMapsMapController? _mapController;
  late final AnimationController _sheetController;
  bool _sheetExpanded = false;
  String _searchText = '';

  // Default camera: Yaoundé centre.
  static const _defaultCenter = MhjMapsLatLng(lat: 3.848, lng: 11.502);

  @override
  void initState() {
    super.initState();
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    // Redraw pins whenever the artisan list changes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(mapArtisansProvider, (previous, next) {
        next.whenData((artisans) {
          _fitCameraToPins(artisans);
        });
      }, fireImmediately: true);
    });
  }

  void _fitCameraToPins(List<ArtisanDirectoryEntry> artisans) {
    final controller = _mapController;
    if (controller == null) return;
    if (artisans.isEmpty) return;

    final points = <LatLng>[];
    for (final a in artisans) {
      if (a.latitude == null || a.longitude == null) continue;
      points.add(LatLng(a.latitude!, a.longitude!));
    }
    if (points.isEmpty) return;

    // Include the device location if available.
    final origin = ref.read(currentLocationProvider).valueOrNull;
    if (origin != null) {
      points.add(LatLng(origin.latitude, origin.longitude));
    }

    try {
      controller.mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(80),
        ),
      );
    } catch (_) {
      // fitCamera can throw when points are too close. Ignore.
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _syncSheet() {
    if (_sheetExpanded) {
      _sheetController.forward();
    } else {
      _sheetController.reverse();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final artisansAsync = ref.watch(mapArtisansProvider);
    final selected = ref.watch(selectedMapArtisanProvider);

    // Keep the sheet expanded when a pin is selected.
    if ((selected != null) != _sheetExpanded) {
      _sheetExpanded = selected != null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncSheet());
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ── Map canvas ──
            Positioned.fill(
              child: MhjMapsMap(
                center: _defaultCenter,
                zoom: 11,
                minZoom: 8,
                maxZoom: 18,
                tileProvider: MhjMapsTileProvider.openStreetMap,
                onMapCreated: (controller) {
                  _mapController = controller;
                },

                additionalLayers: [
                  MarkerLayer(
                    markers: artisansAsync.maybeWhen(
                      data: (artisans) => artisans
                          .where(
                            (a) => a.latitude != null && a.longitude != null,
                          )
                          .map(
                            (a) => Marker(
                              point: LatLng(a.latitude!, a.longitude!),
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              child: ArtisanMapPin(
                                artisan: a,
                                isSelected: selected?.id == a.id,
                                onTap: () {
                                  ref
                                          .read(
                                            selectedMapArtisanProvider.notifier,
                                          )
                                          .state =
                                      a;
                                },
                              ),
                            ),
                          )
                          .toList(),
                      orElse: () => const [],
                    ),
                  ),
                ],
                onCameraMove: (center, zoom) {
                  // Compute a rough bounds from the center + zoom.
                  // The wrapper doesn't expose bounds directly, so we
                  // approximate: at zoom 11, ~0.05° per screen height.
                  final delta = 0.05 * (11 / zoom);
                  ref.read(mapBoundsProvider.notifier).state = MapBounds(
                    north: center.lat + delta,
                    south: center.lat - delta,
                    east: center.lng + delta * 0.6,
                    west: center.lng - delta * 0.6,
                  );
                },
                onTap: (_) {
                  // Dismiss the selection when the user taps empty map.
                  if (ref.read(selectedMapArtisanProvider) != null) {
                    ref.read(selectedMapArtisanProvider.notifier).state = null;
                  }
                },
              ),
            ),

            // ── Top bar ──
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: MapTopBar(
                onBack: () => context.pop(),
                onSearchChanged: (v) => setState(() => _searchText = v),
                searchText: _searchText,
                onFilterTap: () {},
                hasActiveFilter: ref.watch(mapFilterProvider) != null,
              ),
            ),

            // ── Floating FABs ──
            Positioned(
              right: 16,
              bottom: _sheetExpanded ? 544 : 336,
              child: Column(
                children: [
                  _CircleFab(icon: Icons.my_location, onTap: _recenter),
                  const SizedBox(height: 12),
                  _CircleFab(
                    icon: Icons.format_list_bulleted,
                    onTap: () => context.pop(),
                  ),
                ],
              ),
            ),

            // ── Bottom sheet ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                height: _sheetExpanded ? 528 : 320,
                child: ArtisanMapBottomSheet(isExpanded: _sheetExpanded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recenter() async {
    final service = ref.read(locationServiceProvider);
    final result = await service.getCurrentPosition();
    if (!mounted) return;
    if (!result.isGranted || result.point == null) return;

    final controller = _mapController;
    if (controller == null) return;

    controller.mapController.move(
      LatLng(result.point!.latitude, result.point!.longitude),
      14,
    );
  }
}

class _CircleFab extends StatelessWidget {
  const _CircleFab({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.borderLight.withValues(alpha: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 22, color: AppColors.primary),
      ),
    );
  }
}
