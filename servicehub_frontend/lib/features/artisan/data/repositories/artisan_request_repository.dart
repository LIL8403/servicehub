import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../../customer/domain/models/service_request.dart';
import '../../domain/models/artisan_request_summary.dart';

class ArtisanRequestRepository {
  ArtisanRequestRepository({required this.apiService});

  final ApiService apiService;

  /// Returns all requests assigned to the current artisan. The backend
  /// endpoint is expected to support filtering by status; for now we
  /// fetch everything and let the UI partition it.
  Future<List<ArtisanRequestSummary>> listRequests() async {
    try {
      final response = await apiService.authenticatedGet(
        '/artisan/service-requests',
      );
      // ignore: avoid_print
      print('ARTISAN RAW: ${response.body}');
      // ignore: avoid_print
      print('ARTISAN RAW LENGTH: ${response.body.length}');

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['service_requests'] as List?) ?? const [];

      return list
          .whereType<Map<String, dynamic>>()
          .map(ArtisanRequestSummary.fromJson)
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load requests: $e');
    }
  }

  /// Fetches the full details of one request, including the customer,
  /// artisan, service, images, and embedded lifecycle data. Uses the
  /// same shape as the customer-side `fetchRequestDetails`, since the
  /// backend returns the same `service_request` payload.
  Future<ServiceRequest> fetchRequestDetails(String requestId) async {
    if (requestId.isEmpty) {
      throw const ApiException(
        message: 'A request ID is required.',
        statusCode: 400,
      );
    }

    try {
      final response = await apiService.authenticatedGet(
        '/artisan/service-requests/$requestId',
      );

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
      throw ApiException(message: 'Failed to load request details: $e');
    }
  }

  /// Accepts an incoming request. Transitions the request from
  /// `pending_artisan_response` to `artisan_approved`.
  Future<ServiceRequest> approve(String requestId) async {
    return _postAndParse(
      path: '/artisan/service-requests/$requestId/approve',
      actionLabel: 'accept request',
    );
  }

  /// Declines an incoming request. Returns the request to
  /// `awaiting_artisan_selection` on the customer's side.
  Future<ServiceRequest> decline(String requestId, {String? reason}) async {
    return _postAndParse(
      path: '/artisan/service-requests/$requestId/decline',
      body: reason != null && reason.trim().isNotEmpty
          ? {'reason': reason.trim()}
          : null,
      actionLabel: 'decline request',
    );
  }

  /// Marks the artisan as ready to start work. Transitions `booked`
  /// to `in_progress`.
  Future<ServiceRequest> start(String requestId) async {
    return _postAndParse(
      path: '/artisan/service-requests/$requestId/start',
      actionLabel: 'start job',
    );
  }

  /// Reports job completion. Transitions `in_progress` to
  /// `awaiting_confirmation`.
  Future<ServiceRequest> reportCompletion(
    String requestId, {
    String? notes,
  }) async {
    return _postAndParse(
      path: '/artisan/service-requests/$requestId/completion',
      body: notes != null && notes.trim().isNotEmpty
          ? {'notes': notes.trim()}
          : null,
      actionLabel: 'report completion',
    );
  }

  /// Submits a quotation. Transitions `artisan_approved` (or
  /// `inspection_completed`) to `quotation_received`.
  Future<ServiceRequest> submitQuotation(
    String requestId, {
    required double laborAmount,
    required String scope,
    required String validUntil,
    String? notes,
  }) async {
    return _postAndParse(
      path: '/artisan/service-requests/$requestId/quotation',
      body: {
        'labor_amount': laborAmount,
        'currency': 'XAF',
        'scope': scope,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'valid_until': validUntil,
      },
      actionLabel: 'submit quotation',
    );
  }

  /// Proposes materials for the customer to approve.
  Future<ServiceRequest> proposeMaterials(
    String requestId, {
    required List<Map<String, dynamic>> materials,
  }) async {
    return _postAndParse(
      path: '/artisan/service-requests/$requestId/materials',
      body: {'materials': materials},
      actionLabel: 'propose materials',
    );
  }

  /// Completes an inspection. Transitions `inspection_scheduled` to
  /// `inspection_completed`.
  Future<ServiceRequest> completeInspection(
    String requestId, {
    required String findings,
  }) async {
    return _postAndParse(
      path: '/artisan/service-requests/$requestId/inspection/complete',
      body: {'findings': findings},
      actionLabel: 'complete inspection',
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
