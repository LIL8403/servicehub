import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/api/token_storage.dart';
import '../../../../core/constants/api_constants.dart';

/// A reference to an uploaded evidence file. Matches the shape the
/// backend returns from `POST /customer/disputes/evidence`.
class EvidenceReference {
  const EvidenceReference({
    required this.id,
    required this.path,
    required this.name,
    required this.mimeType,
    required this.size,
  });

  final String id;
  final String path;
  final String name;
  final String mimeType;
  final int size;

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'name': name,
    'mime_type': mimeType,
    'size': size,
  };

  factory EvidenceReference.fromJson(Map<String, dynamic> json) {
    return EvidenceReference(
      id: json['id']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A lightweight representation of an opened dispute.
class DisputeHandle {
  const DisputeHandle({
    required this.id,
    required this.status,
    required this.reason,
  });

  final String id;
  final String status;
  final String reason;

  factory DisputeHandle.fromJson(Map<String, dynamic> json) {
    return DisputeHandle(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'opened',
      reason: json['reason']?.toString() ?? '',
    );
  }
}

class DisputeRepository {
  DisputeRepository({
    required this.apiService,
    TokenStorage? tokenStorage,
  }) : _tokenStorage = tokenStorage ?? const TokenStorage();

  final ApiService apiService;
  final TokenStorage _tokenStorage;

  /// Uploads evidence files and returns their references.
  ///
  /// This is the first phase of the two-phase dispute flow. The
  /// references returned here are passed into [open] as the `evidence`
  /// array.
  Future<List<EvidenceReference>> uploadEvidence(List<File> files) async {
    if (files.isEmpty) return const [];
    if (files.length > 5) {
      throw const ApiException(
        message: 'You can upload up to 5 files.',
        statusCode: 400,
      );
    }

    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Authentication token not found.',
        statusCode: 401,
      );
    }

    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/customer/disputes/evidence',
      );

      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token';

      for (final file in files) {
        request.files.add(
          await http.MultipartFile.fromPath('files[]', file.path),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message:
              _extractError(response.body) ??
              'Failed to upload evidence (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final refs = (json['references'] as List?) ?? const [];

      return refs
          .whereType<Map<String, dynamic>>()
          .map(EvidenceReference.fromJson)
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to upload evidence: $e');
    }
  }

  /// Opens a dispute against a service request.
  ///
  /// The backend accepts:
  ///   - `reason` (3-120 chars) — short category label
  ///   - `description` (10-2000 chars) — detailed story
  ///   - `urgency` — optional 'low' | 'medium' | 'high'
  ///   - `evidence` — array of references from [uploadEvidence]
  Future<DisputeHandle> open({
    required String requestId,
    required String reason,
    required String description,
    String? urgency,
    List<EvidenceReference> evidence = const [],
  }) async {
    if (requestId.isEmpty) {
      throw const ApiException(
        message: 'A request ID is required to open a dispute.',
        statusCode: 400,
      );
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.length < 3 || trimmedReason.length > 120) {
      throw const ApiException(
        message: 'The dispute reason must be between 3 and 120 characters.',
        statusCode: 400,
      );
    }
    final trimmedDescription = description.trim();
    if (trimmedDescription.length < 10 || trimmedDescription.length > 2000) {
      throw const ApiException(
        message:
            'The dispute description must be between 10 and 2000 characters.',
        statusCode: 400,
      );
    }

    try {
      final response = await apiService.authenticatedPost(
        '/customer/service-requests/$requestId/disputes',
        body: {
          'reason': trimmedReason,
          'description': trimmedDescription,
          'urgency': ?urgency,
          if (evidence.isNotEmpty)
            'evidence': evidence.map((e) => e.toJson()).toList(),
        },
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final dispute = json['dispute'] as Map<String, dynamic>?;

      if (dispute == null) {
        throw const ApiException(
          message: 'The server returned an unexpected response format.',
          statusCode: 500,
        );
      }

      return DisputeHandle.fromJson(dispute);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to open dispute: $e');
    }
  }

  /// Adds a message or additional evidence to an existing dispute.
  Future<DisputeHandle> addEvidence({
    required String disputeId,
    required String message,
    List<EvidenceReference> evidence = const [],
  }) async {
    if (disputeId.isEmpty) {
      throw const ApiException(
        message: 'A dispute ID is required to add evidence.',
        statusCode: 400,
      );
    }

    try {
      final response = await apiService.authenticatedPost(
        '/customer/disputes/$disputeId/evidence',
        body: {
          'message': message.trim(),
          if (evidence.isNotEmpty)
            'evidence': evidence.map((e) => e.toJson()).toList(),
        },
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final dispute = json['dispute'] as Map<String, dynamic>?;

      if (dispute == null) {
        throw const ApiException(
          message: 'The server returned an unexpected response format.',
          statusCode: 500,
        );
      }

      return DisputeHandle.fromJson(dispute);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to add evidence: $e');
    }
  }

  String? _extractError(String body) {
    if (body.isEmpty) return null;
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        if (json['message'] is String) return json['message'] as String;
        if (json['error'] is Map && json['error']['message'] is String) {
          return json['error']['message'] as String;
        }
      }
    } catch (_) {
      // Ignore.
    }
    return null;
  }
}
