import 'dart:convert';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// A single geographic point with optional display label.
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude, this.label});

  final double latitude;
  final double longitude;
  final String? label;

  Map<String, dynamic> toGeoJson({String? label}) => {
    'type': 'Point',
    'coordinates': [longitude, latitude],
    'label': ?label,
  };
}

enum LocationAvailability {
  granted,
  denied,
  deniedForever,
  servicesDisabled,
  unsupported,
}

/// The outcome of requesting the user's current position.
class LocationResult {
  const LocationResult._({
    required this.availability,
    this.point,
    this.errorMessage,
  });

  factory LocationResult.granted(GeoPoint point) => LocationResult._(
    availability: LocationAvailability.granted,
    point: point,
  );

  factory LocationResult.denied([String? message]) => LocationResult._(
    availability: LocationAvailability.denied,
    errorMessage: message,
  );

  factory LocationResult.deniedForever() =>
      const LocationResult._(availability: LocationAvailability.deniedForever);

  factory LocationResult.servicesDisabled() => const LocationResult._(
    availability: LocationAvailability.servicesDisabled,
  );

  factory LocationResult.unsupported() =>
      const LocationResult._(availability: LocationAvailability.unsupported);

  final LocationAvailability availability;
  final GeoPoint? point;
  final String? errorMessage;

  bool get isGranted => availability == LocationAvailability.granted;
}

/// Wraps device location and address lookups. The UI never talks to
/// `geolocator` or Nominatim directly.
class LocationService {
  LocationService({
    http.Client? httpClient,
    this.nominatimBaseUrl = 'https://nominatim.openstreetmap.org',
    this.userAgent = 'ServiceHUB/1.0 (contact: hello@servicehub.cm)',
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final String nominatimBaseUrl;
  final String userAgent;

  /// Yaoundé — fallback when device location is unavailable.
  static const GeoPoint fallbackYaounde = GeoPoint(
    latitude: 4.0511,
    longitude: 9.7679,
    label: 'Yaoundé',
  );

  Future<LocationResult> getCurrentPosition({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return LocationResult.servicesDisabled();

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationResult.deniedForever();
      }
      if (permission == LocationPermission.denied) {
        return LocationResult.denied();
      }

      // 1) Return the last known position instantly if it's fresh.
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          final age = DateTime.now().difference(last.timestamp);
          if (age.inMinutes < 10) {
            return LocationResult.granted(
              GeoPoint(latitude: last.latitude, longitude: last.longitude),
            );
          }
        }
      } catch (_) {
        // Ignore; fall through to a live fix.
      }

      // 2) Live fix — try medium accuracy, then fall back to low.
      for (final accuracy in [LocationAccuracy.medium, LocationAccuracy.low]) {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: accuracy,
              timeLimit: timeout,
            ),
          );
          return LocationResult.granted(
            GeoPoint(
              latitude: position.latitude,
              longitude: position.longitude,
            ),
          );
        } catch (_) {
          // Try the next accuracy level.
        }
      }

      return LocationResult.denied(
        'Unable to get your location. Try again outdoors or enter your address manually.',
      );
    } catch (e) {
      return LocationResult.denied(e.toString());
    }
  }

  /// Searches for an address, restricted to Cameroon.
  /// Returns the top match, or null if nothing sensible is found.
  /// Searches for an address, restricted to Cameroon.
  Future<GeoPoint?> geocode(String address) async {
    final trimmed = address.trim();
    if (trimmed.length < 4) return null;

    try {
      final uri = Uri.parse(
        '$nominatimBaseUrl/search'
        '?q=${Uri.encodeComponent(trimmed)}'
        '&format=json'
        '&limit=1'
        '&addressdetails=1'
        '&countrycodes=cm',
      );

      final response = await _httpClient
          .get(
            uri,
            headers: {'User-Agent': userAgent, 'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 || response.body.isEmpty) return null;

      final list = jsonDecode(response.body) as List?;
      if (list == null || list.isEmpty) return null;

      final first = list.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lng = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lng == null) return null;

      return GeoPoint(
        latitude: lat,
        longitude: lng,
        label: first['display_name']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final uri = Uri.parse(
        '$nominatimBaseUrl/reverse'
        '?lat=$latitude&lon=$longitude&format=json',
      );

      final response = await _httpClient
          .get(
            uri,
            headers: {'User-Agent': userAgent, 'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 || response.body.isEmpty) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['display_name']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Great-circle distance between two points, in km.
  double distanceKm(GeoPoint a, GeoPoint b) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);

    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  double _toRad(double deg) => deg * math.pi / 180.0;
}
