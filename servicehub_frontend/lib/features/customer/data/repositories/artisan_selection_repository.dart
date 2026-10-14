import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../domain/models/eligible_artisans_response.dart';

class ArtisanSelectionRepository {
  ArtisanSelectionRepository({required this.apiService});

  final ApiService apiService;

  Future<EligibleArtisansResponse> fetchEligibleArtisans(
    String requestId,
  ) async {
    try {
      final response = await apiService.authenticatedGet(
        '/customer/service-requests/$requestId/eligible-artisans',
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return EligibleArtisansResponse.fromJson(json);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load artisans: $e');
    }
  }

  Future<Map<String, dynamic>> selectArtisan({
    required String requestId,
    required String artisanId,
  }) async {
    try {
      final response = await apiService.authenticatedPost(
        '/customer/service-requests/$requestId/select-artisan',
        body: {'artisan_profile_id': artisanId},
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to select artisan: $e');
    }
  }
}