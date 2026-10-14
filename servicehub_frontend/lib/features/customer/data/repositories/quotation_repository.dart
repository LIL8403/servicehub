import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../domain/models/service_request.dart';

/// Handles customer-side quotation decisions:
/// accepting, rejecting, and retrieving a single quotation.
class QuotationRepository {
  QuotationRepository({required this.apiService});

  final ApiService apiService;

  /// Accepts the current quotation for the given request.
  /// Returns the updated [ServiceRequest] so the caller can transition
  /// the UI to the next state (typically `payment_pending`).
  Future<ServiceRequest> accept(String requestId) async {
    return _postAndParse(
      path: '/customer/service-requests/$requestId/quotation/accept',
      actionLabel: 'accept quotation',
    );
  }

  /// Rejects the current quotation, optionally with a reason.
  /// Returns the updated [ServiceRequest].
  Future<ServiceRequest> reject(
    String requestId, {
    String? reason,
  }) async {
    return _postAndParse(
      path: '/customer/service-requests/$requestId/quotation/reject',
      body: reason != null && reason.trim().isNotEmpty
          ? {'reason': reason.trim()}
          : null,
      actionLabel: 'reject quotation',
    );
  }

  Future<ServiceRequest> _postAndParse({
    required String path,
    required String actionLabel,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await apiService.authenticatedPost(path, body: body);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final requestJson = json['service_request'] as Map<String, dynamic>?;

      if (requestJson == null) {
        throw const ApiException(
          message: 'The server returned an unexpected response format.',
          statusCode: 500,
        );
      }

      return ServiceRequest.fromJson(requestJson);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to $actionLabel: $e');
    }
  }
}