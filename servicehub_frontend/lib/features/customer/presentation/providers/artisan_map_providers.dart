import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../core/location/location_service.dart';
import '../../domain/models/artisan_directory_entry.dart';
import '../providers/artisan_directory_providers.dart';

/// Currently selected artisan on the map. Null when no pin is tapped.
final selectedMapArtisanProvider = StateProvider<ArtisanDirectoryEntry?>(
  (ref) => null,
);

/// Active map filter chip. `null` = "All".
final mapFilterProvider = StateProvider<String?>((ref) => null);

/// Bounding box currently visible on the map. Set by `onCameraMove`.
final mapBoundsProvider = StateProvider<MapBounds?>((ref) => null);

/// Camera target — set when the user taps "recenter". The map page
/// listens for changes and animates the camera to the new point.
final mapRecenterProvider = StateProvider<GeoPoint?>((ref) => null);

@immutable
class MapBounds {
  const MapBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  final double north;
  final double south;
  final double east;
  final double west;

  bool contains(double lat, double lng) {
    return lat >= south && lat <= north && lng >= west && lng <= east;
  }
}

/// Artisans visible in the current viewport, filtered by the active
/// chip. Uses the existing directory endpoint with a larger limit
/// (60) and filters client-side by the bounds + filter.
///
/// The existing `/api/artisans` endpoint doesn't support a bounding
/// box param yet, so we fetch a generous batch once and slice it
/// locally. When the backend gains a `bbox` filter, swap the fetch
/// for a bounds-scoped call.
final mapArtisansProvider =
    FutureProvider.autoDispose<List<ArtisanDirectoryEntry>>((ref) async {
      final serviceId = ref.watch(mapFilterProvider);

      final origin = ref.watch(currentLocationProvider).valueOrNull;

      // Fetch a larger set than the Discover tab (30) because a map
      // viewport can hold many more pins than a list.
      final query = (
        serviceId: serviceId,
        search: null,
        latitude: origin?.latitude,
        longitude: origin?.longitude,
        limit: 60,
      );

      final artisans = await ref.watch(artisanDirectoryProvider(query).future);

      // Return everything the API gives us. The map's own viewport
      // clipping handles visibility, and the pins layer rebuilds from
      // this list on every provider change.
      //
      // The bounds filter was too aggressive for edge cases (approximate
      // viewport math) and returned 0 artisans when pins were just
      // outside the tiny initial viewport. Bounds-driven fetching is a
      // post-MVP optimization.
      return artisans
          .where((a) {
            return a.latitude != null && a.longitude != null;
          })
          .toList(growable: false);
    });

/// Convenience: the count for the bottom sheet header.
final mapArtisanCountProvider = Provider<int>((ref) {
  return ref.watch(mapArtisansProvider).valueOrNull?.length ?? 0;
});

/// Resolves distance from device location for a given artisan, or
/// null when either side lacks coordinates.
double? mapDistanceKm(WidgetRef ref, ArtisanDirectoryEntry artisan) {
  final origin = ref.read(currentLocationProvider).valueOrNull;
  if (origin == null) return null;
  if (artisan.latitude == null || artisan.longitude == null) return null;
  return ref
      .read(locationServiceProvider)
      .distanceKm(
        origin,
        GeoPoint(latitude: artisan.latitude!, longitude: artisan.longitude!),
      );
}
