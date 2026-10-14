import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';

class ArtisanProfileRepository {
  ArtisanProfileRepository({required this.apiService});

  final ApiService apiService;

  /// Fetches the current artisan's professional profile.
  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final response = await apiService.authenticatedGet('/artisan/profile');
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      // The backend returns {"profile": {...}}. Fall back to the
      // response itself if the shape changes.
      return json['profile'] as Map<String, dynamic>? ?? json;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load profile: $e');
    }
  }

  /// Updates the artisan's professional profile.
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await apiService.authenticatedPatch(
        '/artisan/profile',
        body: payload,
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['profile'] as Map<String, dynamic>? ?? json;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to update profile: $e');
    }
  }
}