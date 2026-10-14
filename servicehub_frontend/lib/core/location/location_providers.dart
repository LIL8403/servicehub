import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'location_service.dart';
import 'saved_location_storage.dart';

final savedLocationStorageProvider = Provider<SavedLocationStorage>(
  (ref) => SavedLocationStorage(),
);

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// The user's current position, cached for the session. When denied
/// or unavailable, resolves to the Yaoundé fallback so downstream
/// widgets always have something to work with.
final currentLocationProvider = FutureProvider<GeoPoint>((ref) async {
  final service = ref.watch(locationServiceProvider);
  final result = await service.getCurrentPosition();

  if (result.isGranted && result.point != null) {
    return result.point!;
  }
  return LocationService.fallbackYaounde;
});

/// Exposes the raw availability so the UI can show the right badge
/// ("GPS Active" vs "Using Yaoundé").
final locationAvailabilityProvider = FutureProvider<LocationAvailability>((
  ref,
) async {
  final service = ref.watch(locationServiceProvider);
  final result = await service.getCurrentPosition();
  return result.availability;
});
