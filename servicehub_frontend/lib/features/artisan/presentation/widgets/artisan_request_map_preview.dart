import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mhj_maps/mhj_maps.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../customer/domain/models/service_request.dart';

/// A static, non-interactive map preview pinned to the request's
/// service location. Tapping is disabled — this is context, not a
/// navigation surface.
///
/// Falls back to a graceful placeholder when the request has no
/// coordinates.
class ArtisanRequestMapPreview extends StatelessWidget {
  const ArtisanRequestMapPreview({super.key, required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final lat = request.location?.latitude;
    final lng = request.location?.longitude;

    if (lat == null || lng == null) {
      return _placeholder(
        icon: Icons.location_off_outlined,
        label: 'No map location recorded',
      );
    }

    return ClipRRect(
      borderRadius: AppRadii.borderMd,
      child: SizedBox(
        height: 140,
        child: MhjMapsMap(
          center: MhjMapsLatLng(lat: lat, lng: lng),
          zoom: 15,
          interactive: false,
          showAttribution: false,
          showZoomControls: false,
          tileProvider: MhjMapsTileProvider.openStreetMap,
          additionalLayers: [
            // A single marker at the request location.
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(lat, lng),
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.home_repair_service,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder({required IconData icon, required String label}) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.35),
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.borderLight),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: AppColors.textMuted),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}