import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../domain/enums/urgency_level.dart';
import '../../domain/models/service_request.dart';
import '../../domain/models/service_request_draft.dart';

class ServiceRequestRepository {
  ServiceRequestRepository({required this.apiService});

  final ApiService apiService;

  /// Submits a new service request to the backend.
  ///
  /// Returns a lightweight [SubmittedRequest] containing only the
  /// fields the success screen needs (id, status, AI flag).
  Future<SubmittedRequest> submit({
    required ServiceRequestDraft draft,
    required String serviceId,
  }) async {
    // Build the JSON-able fields once — used by both branches.
    final fields = <String, dynamic>{
      'service_id': serviceId,
      'description': draft.description.trim(),
      'ai_assist_enabled': draft.aiAssistEnabled ? '1' : '0',
      if (draft.urgency != null) 'urgency': _urgencyApiValue(draft.urgency!),
    };

    // Treat (0,0) as "no coordinates" — it's a client-side sentinel
    // for a typed address that hasn't been geocoded yet. Sending it
    // to MongoDB stores Null Island and breaks artisan matching.
    final lng = draft.locationLongitude;
    final lat = draft.locationLatitude;
    final hasCoords = lng != null && lat != null && lng != 0.0 && lat != 0.0;

    // Preferred schedule
    if (draft.preferredDate != null || draft.isFlexible) {
      if (draft.preferredDate != null) {
        fields['preferred_schedule[date]'] = _formatDate(draft.preferredDate!);
      }
      final window = _scheduleWindow(draft);
      if (window != null) {
        fields['preferred_schedule[window]'] = window;
      }
      if (draft.additionalNotes.trim().isNotEmpty) {
        fields['preferred_schedule[notes]'] = draft.additionalNotes.trim();
      }
    }

    try {
      final hasPhotos = draft.photoFiles.isNotEmpty;

      final http.Response response;
      if (hasPhotos) {
        // Multipart path — required when files are attached.
        final files = <http.MultipartFile>[];
        for (final xfile in draft.photoFiles) {
          files.add(await apiService.multipartFileFromXFile('images[]', xfile));
        }

        // Add location OR address to the multipart fields. The JSON
        // branch below does this inline, but the multipart branch must
        // do it explicitly because `fields` is pre-built at the top.
        if (hasCoords) {
          fields['location[label]'] = draft.formattedAddress?.trim() ?? '';
          fields['location[type]'] = 'Point';
          fields['location[coordinates][0]'] = lng.toString();
          fields['location[coordinates][1]'] = lat.toString();
        } else if ((draft.formattedAddress ?? '').trim().isNotEmpty) {
          fields['address'] = draft.formattedAddress!.trim();
        }

        response = await apiService.postMultipart(
          '/customer/service-requests',
          fields: fields.map((k, v) => MapEntry(k, v.toString())),
          files: files,
          authenticated: true,
        );
      } else {
        // JSON path — same as before for the no-photo case.
        final jsonBody = <String, dynamic>{
          'service_id': serviceId,
          'description': draft.description.trim(),
          'ai_assist_enabled': draft.aiAssistEnabled,
          if (draft.urgency != null)
            'urgency': _urgencyApiValue(draft.urgency!),
          if (hasCoords)
            'location': {
              'label': draft.formattedAddress?.trim() ?? '',
              'type': 'Point',
              'coordinates': [lng, lat],
            }
          else if ((draft.formattedAddress ?? '').trim().isNotEmpty)
            'address': draft.formattedAddress!.trim(),
          if (draft.preferredDate != null || draft.isFlexible)
            'preferred_schedule': {
              if (draft.preferredDate != null)
                'date': _formatDate(draft.preferredDate!),
              'window': _scheduleWindow(draft),
              'notes': draft.additionalNotes.trim().isEmpty
                  ? null
                  : draft.additionalNotes.trim(),
            },
        };

        response = await apiService.authenticatedPost(
          '/customer/service-requests',
          body: jsonBody,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final request = json['service_request'] as Map<String, dynamic>;

      return SubmittedRequest(
        id: request['_id']?.toString() ?? request['id']?.toString() ?? '',
        status: request['status']?.toString() ?? 'unknown',
        aiAssistEnabled: request['ai_assist_enabled'] == true,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to submit request: $e');
    }
  }

  /// Fetches the full details of a single service request, including
  /// its status history, selected artisan, and service snapshot.
  ///
  /// Used by the Request Tracking screen to render the correct view
  /// for the current [ServiceRequestStatus].
  Future<ServiceRequest> fetchRequestDetails(String requestId) async {
    if (requestId.isEmpty) {
      throw const ApiException(
        message: 'A request ID is required to fetch request details.',
        statusCode: 400,
      );
    }

    try {
      final response = await apiService.authenticatedGet(
        '/customer/service-requests/$requestId',
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

  /// Retries artisan matching for a request that is currently in
  /// `no_artisan_available`. On success, the backend may move the
  /// request to `awaiting_artisan_selection` (matching succeeded) or
  /// leave it in `no_artisan_available` (still no luck). Either way,
  /// we return the updated request so the caller can decide what to do.
  Future<ServiceRequest> retryMatching(String requestId) async {
    if (requestId.isEmpty) {
      throw const ApiException(
        message: 'A request ID is required to retry matching.',
        statusCode: 400,
      );
    }

    try {
      final response = await apiService.authenticatedPost(
        '/customer/service-requests/$requestId/retry-matching',
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
      throw ApiException(message: 'Failed to retry matching: $e');
    }
  }

  /// Confirms that the customer has inspected the completed job.
  /// Backend transitions the request to `completed` and releases escrow.
  Future<ServiceRequest> confirmCompletion(String requestId) async {
    if (requestId.isEmpty) {
      throw const ApiException(
        message: 'A request ID is required to confirm completion.',
        statusCode: 400,
      );
    }

    try {
      final response = await apiService.authenticatedPost(
        '/customer/service-requests/$requestId/completion/confirm',
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
      throw ApiException(message: 'Failed to confirm completion: $e');
    }
  }

  String _urgencyApiValue(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.low:
        return 'low';
      case UrgencyLevel.medium:
        return 'medium';
      case UrgencyLevel.high:
        return 'high';
    }
  }

  String? _scheduleWindow(ServiceRequestDraft draft) {
    if (draft.isFlexible) {
      return 'Flexible';
    }
    final earliest = draft.preferredStartTime;
    final latest = draft.preferredEndTime;
    if (earliest != null && latest != null) {
      return '$earliest – $latest';
    }
    if (earliest != null) {
      return 'After $earliest';
    }
    if (latest != null) {
      return 'Before $latest';
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class SubmittedRequest {
  const SubmittedRequest({
    required this.id,
    required this.status,
    required this.aiAssistEnabled,
  });

  final String id;
  final String status;
  final bool aiAssistEnabled;
}
