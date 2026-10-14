import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../domain/models/quotation_analysis.dart';
import '../../domain/models/request_understanding.dart';

/// Single entry point for the customer-facing `/ai/*` endpoints.
///
/// All methods return parsed models and throw [ApiException] on transport
/// or non-2xx responses. AI unavailability is signalled via
/// `available == false` on the model — NOT via an exception — so the UI
/// can degrade gracefully without try/catch noise.
class AiRepository {
  AiRepository({required this.apiService});

  final ApiService apiService;

  /// `POST /ai/understand-draft` — pre-submission draft analysis.
  Future<RequestUnderstanding> understandDraft({
    required String description,
    String? serviceId,
    Map<String, dynamic>? preferredSchedule,
  }) async {
    try {
      final response = await apiService.authenticatedPost(
        '/ai/understand-draft',
        body: {
          'description': description,
          if (serviceId != null && serviceId.isNotEmpty)
            'service_id': serviceId,
          'preferred_schedule': ?preferredSchedule,
        },
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final envelope = json['request_understanding'];
      if (envelope is! Map<String, dynamic>) {
        return const RequestUnderstanding(
          available: false,
          reason: 'unavailable',
        );
      }
      return RequestUnderstanding.fromEnvelope(envelope);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'AI request failed: $e');
    }
  }

  /// `POST /ai/service-requests/{id}/understand` — post-submission analysis.
  Future<RequestUnderstanding> understandRequest(String requestId) async {
    try {
      final response = await apiService.authenticatedPost(
        '/ai/service-requests/$requestId/understand',
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final envelope = json['request_understanding'];
      if (envelope is! Map<String, dynamic>) {
        return const RequestUnderstanding(
          available: false,
          reason: 'unavailable',
        );
      }
      return RequestUnderstanding.fromEnvelope(envelope);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'AI request failed: $e');
    }
  }

  /// `POST /ai/service-requests/{id}/quotation/analyze`
  Future<QuotationAnalysis> analyzeQuotation(String requestId) async {
    try {
      final response = await apiService.authenticatedPost(
        '/ai/service-requests/$requestId/quotation/analyze',
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final envelope = json['quotation_analysis'];
      if (envelope is! Map<String, dynamic>) {
        return const QuotationAnalysis(
          available: false,
          reason: 'unavailable',
        );
      }
      return QuotationAnalysis.fromEnvelope(envelope);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'AI quotation analysis failed: $e');
    }
  }
}