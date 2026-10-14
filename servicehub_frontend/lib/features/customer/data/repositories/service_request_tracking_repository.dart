import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../domain/models/service_request_tracking.dart';

class ServiceRequestTrackingRepository {
  ServiceRequestTrackingRepository({required this.apiService});
  final ApiService apiService;

  Future<ServiceRequestTracking> fetch(String requestId) async {
    try {
      final response = await apiService.authenticatedGet('/customer/service-requests/$requestId/tracking');
      return ServiceRequestTracking.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(message: 'Unable to load this request: $error');
    }
  }

  Future<void> retryMatching(String requestId) => _post('/customer/service-requests/$requestId/retry-matching');

  Future<void> changeArtisan(String requestId) => _post('/customer/service-requests/$requestId/change-artisan');

  Future<void> confirmCompletion(String requestId) => _post('/customer/service-requests/$requestId/completion/confirm');

  Future<void> cancel(String requestId, String reason) => _post(
        '/customer/service-requests/$requestId/cancel',
        body: {'reason': reason},
      );

  Future<void> _post(String endpoint, {Map<String, dynamic>? body}) async {
    await apiService.authenticatedPost(endpoint, body: body);
  }
}
