import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../domain/models/service_offering.dart';

class ArtisanServiceOfferingRepository {
  ArtisanServiceOfferingRepository({required this.apiService});

  final ApiService apiService;

  Future<List<ServiceOffering>> list() async {
    try {
      final response = await apiService.authenticatedGet(
        '/artisan/service-offerings',
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['offerings'] as List?) ?? const [];

      return list
          .whereType<Map<String, dynamic>>()
          .map(ServiceOffering.fromJson)
          .where((o) => o.offeringId.isNotEmpty)
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load offerings: $e');
    }
  }

  Future<ServiceOffering> create({
    required String serviceId,
    double? startingPrice,
    String? description,
    bool isActive = true,
  }) async {
    try {
      final response = await apiService.authenticatedPost(
        '/artisan/service-offerings',
        body: {
          'service_id': serviceId,
          'starting_price': ?startingPrice,
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          'is_active': isActive,
        },
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final offering = json['offering'] as Map<String, dynamic>?;
      if (offering == null) {
        throw const ApiException(
          message: 'Unexpected response shape.',
          statusCode: 500,
        );
      }
      return ServiceOffering.fromJson(offering);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to add offering: $e');
    }
  }

  Future<ServiceOffering> update(
    String offeringId, {
    double? startingPrice,
    String? description,
    bool? isActive,
    bool clearStartingPrice = false,
    bool clearDescription = false,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (clearStartingPrice) {
        body['starting_price'] = null;
      } else if (startingPrice != null) {
        body['starting_price'] = startingPrice;
      }
      if (clearDescription) {
        body['description'] = null;
      } else if (description != null) {
        body['description'] = description;
      }
      if (isActive != null) body['is_active'] = isActive;

      final response = await apiService.authenticatedPatch(
        '/artisan/service-offerings/$offeringId',
        body: body,
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final offering = json['offering'] as Map<String, dynamic>?;
      if (offering == null) {
        throw const ApiException(
          message: 'Unexpected response shape.',
          statusCode: 500,
        );
      }
      return ServiceOffering.fromJson(offering);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to update offering: $e');
    }
  }

  Future<void> destroy(String offeringId) async {
    try {
      await apiService.authenticatedDelete(
        '/artisan/service-offerings/$offeringId',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to remove offering: $e');
    }
  }
}
