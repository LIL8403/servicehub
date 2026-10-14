import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../domain/models/artisan_directory_entry.dart';

class ArtisanDirectoryRepository {
  ArtisanDirectoryRepository({required this.apiService});

  final ApiService apiService;

  /// Fetches artisans from `GET /api/artisans`.
  ///
  /// Optional [serviceId] filters by what they offer, and [search]
  /// filters by name or title. Coordinates are optional; when provided
  /// the backend sorts by distance.
  Future<List<ArtisanDirectoryEntry>> search({
    String? serviceId,
    String? search,
    double? latitude,
    double? longitude,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{
        if (serviceId != null && serviceId.isNotEmpty) 'service_id': serviceId,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (latitude != null) 'lat': latitude.toString(),
        if (longitude != null) 'lng': longitude.toString(),
        if (limit != null) 'limit': limit.toString(),
      };

      final query = queryParams.isEmpty
          ? ''
          : '?${Uri(queryParameters: queryParams).query}';

      final response = await apiService.authenticatedGet('/artisans$query');

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['artisans'] as List?) ?? const [];

      return list
          .whereType<Map<String, dynamic>>()
          .map(ArtisanDirectoryEntry.fromJson)
          .where((a) => a.id.isNotEmpty)
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load artisans: $e');
    }
  }

  /// Fetches a single artisan by ID from the public directory.
  ///
  /// The `/api/artisans` endpoint doesn't have a "show one" route,
  /// so we request a page and pick the matching entry. When the
  /// backend adds `/artisans/{id}`, swap this for a single call.
  Future<ArtisanDirectoryEntry?> fetchById(String artisanId) async {
    if (artisanId.isEmpty) return null;

    try {
      final response = await apiService.authenticatedGet('/artisans?limit=100');

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['artisans'] as List?) ?? const [];

      for (final raw in list) {
        if (raw is! Map<String, dynamic>) continue;
        final entry = ArtisanDirectoryEntry.fromJson(raw);
        if (entry.id == artisanId) return entry;
      }
      return null;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load artisan: $e');
    }
  }
}
