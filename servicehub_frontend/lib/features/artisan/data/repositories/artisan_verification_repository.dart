import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/api/token_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/verification_document_type.dart';
import '../../domain/models/verification_status.dart';

/// The verification endpoint returns two pieces at once: the current
/// state of the artisan's application and the config the client uses
/// to render the correct document types.
class VerificationSnapshot {
  const VerificationSnapshot({required this.status, required this.config});

  final VerificationStatus status;
  final VerificationConfig config;
}

class ArtisanVerificationRepository {
  ArtisanVerificationRepository({
    required this.apiService,
    TokenStorage? tokenStorage,
    http.Client? httpClient,
  }) : _tokenStorage = tokenStorage ?? const TokenStorage();

  final ApiService apiService;
  final TokenStorage _tokenStorage;

  Future<VerificationSnapshot> fetch() async {
    try {
      final response = await apiService.authenticatedGet(
        '/artisan/verification',
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final verificationJson = json['verification'] as Map<String, dynamic>?;
      final configJson = json['config'] as Map<String, dynamic>?;

      if (verificationJson == null || configJson == null) {
        throw const ApiException(
          message: 'The server returned an unexpected response format.',
          statusCode: 500,
        );
      }

      return VerificationSnapshot(
        status: VerificationStatus.fromJson(verificationJson),
        config: VerificationConfig.fromJson(configJson),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load verification: $e');
    }
  }

  /// Streams a supporting document's bytes back from the server.
  /// Used by the "View" action on the supporting documents screen.
  ///
  /// Returns a record with the raw bytes and the filename so callers
  /// can write to a temp file or display the image.
  Future<({List<int> bytes, String filename})> downloadSupportingDocument(
    String documentId,
  ) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Authentication token not found.',
        statusCode: 401,
      );
    }

    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/artisan/verification/documents/$documentId/download',
      );

      final response = await http.get(
            uri,
            headers: {'Accept': '*/*', 'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: 'Could not download document (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }

      // Parse filename from the Content-Disposition header if present.
      final disposition = response.headers['content-disposition'] ?? '';
      final match = RegExp(r'filename="?([^"]+)"?').firstMatch(disposition);
      final filename = match?.group(1) ?? 'document';

      return (bytes: response.bodyBytes, filename: filename);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Download failed: $e');
    }
  }

  Future<VerificationSnapshot> saveIdentity({
    required String legalName,
    required String dateOfBirth,
    required String residentialAddress,
  }) async {
    try {
      final response = await apiService.authenticatedPatch(
        '/artisan/verification/identity',
        body: {
          'legal_name': legalName,
          'date_of_birth': dateOfBirth,
          'residential_address': residentialAddress,
        },
      );

      return _parseSnapshot(response.body, null);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to save identity: $e');
    }
  }

  Future<VerificationSnapshot> uploadIdentityDocument({
    required String documentType,
    required String documentNumber,
    String? expiresAt,
    required File front,
    File? back,
  }) async {
    return _multipartPost(
      path: '/artisan/verification/identity/document',
      fields: {
        'document_type': documentType,
        'document_number': documentNumber,
        if (expiresAt != null && expiresAt.isNotEmpty) 'expires_at': expiresAt,
      },
      files: {'front': front, 'back': ?back},
    );
  }

  Future<VerificationSnapshot> uploadSelfie(File selfie) async {
    return _multipartPost(
      path: '/artisan/verification/selfie',
      files: {'selfie': selfie},
    );
  }

  Future<VerificationSnapshot> uploadSupportingDocument({
    required String documentType,
    String? label,
    required File document,
  }) async {
    return _multipartPost(
      path: '/artisan/verification/documents',
      fields: {
        'document_type': documentType,
        if (label != null && label.isNotEmpty) 'label': label,
      },
      files: {'document': document},
    );
  }

  Future<VerificationSnapshot> deleteSupportingDocument(
    String documentId,
  ) async {
    try {
      final response = await apiService.authenticatedDelete(
        '/artisan/verification/documents/$documentId',
      );
      return _parseSnapshot(response.body, null);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to remove document: $e');
    }
  }

  Future<VerificationSnapshot> submit() async {
    try {
      final response = await apiService.authenticatedPost(
        '/artisan/verification/submit',
      );
      return _parseSnapshot(response.body, null);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to submit verification: $e');
    }
  }

  // ============================================================
  // Helpers
  // ============================================================

  Future<VerificationSnapshot> _multipartPost({
    required String path,
    Map<String, String> fields = const {},
    Map<String, File> files = const {},
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Authentication token not found.',
        statusCode: 401,
      );
    }

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$path');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token'
        ..fields.addAll(fields);

      for (final entry in files.entries) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value.path),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message:
              _extractError(response.body) ??
              'Upload failed (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }

      return _parseSnapshot(response.body, null);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Upload failed: $e');
    }
  }

  VerificationSnapshot _parseSnapshot(String body, VerificationConfig? config) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final verificationJson = json['verification'] as Map<String, dynamic>?;
    final configJson = json['config'] as Map<String, dynamic>?;

    if (verificationJson == null) {
      throw const ApiException(
        message: 'The server returned an unexpected response format.',
        statusCode: 500,
      );
    }

    return VerificationSnapshot(
      status: VerificationStatus.fromJson(verificationJson),
      // Save/upload responses don't always return the config; callers
      // can keep the previous one.
      config: configJson != null
          ? VerificationConfig.fromJson(configJson)
          : config ??
                const VerificationConfig(
                  identityDocumentTypes: [],
                  supportingDocumentTypes: [],
                  maxSupportingDocuments: 8,
                  maxFileSizeKb: 5120,
                ),
    );
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
      // Ignore — return the fallback.
    }
    return null;
  }
}
