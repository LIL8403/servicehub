import 'package:shared_preferences/shared_preferences.dart';

/// Persists the customer's most recently used location so the
/// create-request wizard can pre-fill it next time (spec §34).
///
/// Deliberately simple: a single snapshot, not a list. Add a list
/// later if the spec grows into "saved addresses".
class SavedLocationStorage {
  static const _kLabel = 'saved_location_label';
  static const _kLat = 'saved_location_lat';
  static const _kLng = 'saved_location_lng';

  Future<SavedLocation?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final label = prefs.getString(_kLabel);
    final lat = prefs.getDouble(_kLat);
    final lng = prefs.getDouble(_kLng);

    if (label == null || lat == null || lng == null) return null;
    return SavedLocation(label: label, latitude: lat, longitude: lng);
  }

  Future<void> save({
    required String label,
    required double latitude,
    required double longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLabel, label);
    await prefs.setDouble(_kLat, latitude);
    await prefs.setDouble(_kLng, longitude);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLabel);
    await prefs.remove(_kLat);
    await prefs.remove(_kLng);
  }
}

class SavedLocation {
  const SavedLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final double latitude;
  final double longitude;
}
