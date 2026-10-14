import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/api/token_storage.dart';
import '../../../../core/constants/api_constants.dart';

/// One pending artisan application as returned by the admin endpoint.
class PendingArtisan {
  const PendingArtisan({required this.raw});

  /// The raw JSON map. Fields are read on demand by the UI.
  final Map<String, dynamic> raw;

  String get id =>
      raw['id']?.toString() ?? raw['_id']?.toString() ?? '';

  String get _idPrefix =>
      id.length >= 6 ? id.substring(id.length - 6).toUpperCase() : id;

  String get displayId => 'ID: $_idPrefix';

  Map<String, dynamic> get user =>
      (raw['user'] as Map<String, dynamic>?) ?? const {};

  String get fullName {
    final first = user['first_name']?.toString() ?? '';
    final last = user['last_name']?.toString() ?? '';
    if (first.isNotEmpty && last.isNotEmpty) return '$first $last';
    if (first.isNotEmpty) return first;
    if (last.isNotEmpty) return last;
    return user['name']?.toString() ?? 'Unknown artisan';
  }

  String get email => user['email']?.toString() ?? '';

  String get phone => user['phone']?.toString() ?? '';

  String get professionalTitle =>
      raw['professional_title']?.toString() ?? '';

  String get serviceLabel {
    final offerings = raw['service_offerings'];
    if (offerings is List && offerings.isNotEmpty) {
      final first = offerings.first;
      if (first is Map && first['service_reference'] != null) {
        // We only have the reference here, not the name. Fall back to a
        // generic label if the backend doesn't resolve it. The detail
        // panel will resolve it via the service catalog.
        return professionalTitle.isNotEmpty
            ? professionalTitle
            : 'Trade artisan';
      }
    }
    return professionalTitle.isNotEmpty ? professionalTitle : 'Trade artisan';
  }

  String? get legalName => raw['legal_name']?.toString();

  String? get dateOfBirth => raw['date_of_birth']?.toString();

  String? get residentialAddress => raw['residential_address']?.toString();

  Map<String, dynamic>? get identityDocument =>
      raw['identity_document'] as Map<String, dynamic>?;

  Map<String, dynamic>? get selfie =>
      raw['verification_selfie'] as Map<String, dynamic>?;

  List<Map<String, dynamic>> get supportingDocuments {
    final list = raw['verification_documents'];
    if (list is! List) return const [];
    return list.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  DateTime? get submittedAt {
    final submittedAtValue = raw['verification_submitted_at'];
    if (submittedAtValue is String) {
      return DateTime.tryParse(submittedAtValue);
    }
    return null;
  }

  bool get hasIdentityDocument {
    final doc = identityDocument;
    if (doc == null) return false;
    final front = doc['front'];
    return front is Map && front['path'] != null;
  }

  bool get hasSelfie {
    final s = selfie;
    return s != null && s['path'] != null;
  }
}

class AdminVerificationRepository {
  AdminVerificationRepository({
    required this.apiService,
    TokenStorage? tokenStorage,
    http.Client? httpClient,
  })  : _tokenStorage = tokenStorage ?? const TokenStorage(),
        _httpClient = httpClient ?? http.Client();

  final ApiService apiService;
  final TokenStorage _tokenStorage;
  final http.Client _httpClient;

  Future<List<PendingArtisan>> fetchPending() async {
    try {
      final response =
          await apiService.authenticatedGet('/admin/artisans/pending');
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['artisans'] as List?) ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => PendingArtisan(raw: e))
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load queue: $e');
    }
  }

  Future<void> approve(String artisanId) async {
    try {
      await apiService.authenticatedPost(
        '/admin/artisans/$artisanId/approve',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to approve: $e');
    }
  }

  Future<void> reject(String artisanId, String reason) async {
    try {
      await apiService.authenticatedPost(
        '/admin/artisans/$artisanId/reject',
        body: {'rejection_reason': reason},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to reject: $e');
    }
  }

  /// Returns the raw bytes of a verification document. [slot] is one of
  /// `identity-front`, `identity-back`, `selfie`, or `document:{id}`.
  Future<({List<int> bytes, String filename})> downloadDocument({
    required String artisanId,
    required String slot,
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Authentication token not found.',
        statusCode: 401,
      );
    }

    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/admin/artisans/$artisanId/documents/$slot',
      );
      final response = await _httpClient.get(
        uri,
        headers: {
          'Accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: 'Could not load document (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }

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
}