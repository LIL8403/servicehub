import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/api/token_storage.dart';
import '../../../../core/constants/api_constants.dart';

/// A dispute summary as returned by the list endpoint.
class DisputeSummary {
  const DisputeSummary({
    required this.id,
    required this.status,
    required this.reason,
    required this.description,
    required this.urgency,
    required this.reporterId,
    required this.reporterRole,
    required this.reporterName,
    required this.serviceRequestId,
    required this.serviceName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String status;
  final String reason;
  final String description;
  final String? urgency;
  final String reporterId;
  final String reporterRole;
  final String? reporterName;
  final String serviceRequestId;
  final String? serviceName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get shortId =>
      id.length >= 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase();

  factory DisputeSummary.fromJson(Map<String, dynamic> json) {
    return DisputeSummary(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'opened',
      reason: json['reason']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      urgency: json['urgency']?.toString(),
      reporterId: json['reporter_id']?.toString() ?? '',
      reporterRole: json['reporter_role']?.toString() ?? 'customer',
      reporterName: json['reporter_name']?.toString(),
      serviceRequestId: json['service_request_id']?.toString() ?? '',
      serviceName: json['service_name']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

/// A full dispute with all detail fields.
class DisputeDetail {
  const DisputeDetail({
    required this.id,
    required this.serviceRequestId,
    required this.paymentId,
    required this.reporterId,
    required this.reporterRole,
    required this.reporterName,
    required this.reason,
    required this.description,
    required this.urgency,
    required this.evidence,
    required this.updates,
    required this.status,
    required this.priorRequestStatus,
    required this.statusHistory,
    required this.resolution,
    required this.pendingResolution,
    required this.resolutionReference,
    required this.createdAt,
    required this.updatedAt,
    required this.serviceName,
    required this.customerName,
    required this.artisanName,
  });

  final String id;
  final String serviceRequestId;
  final String? paymentId;
  final String reporterId;
  final String reporterRole;
  final String? reporterName;
  final String reason;
  final String description;
  final String? urgency;
  final List<Map<String, dynamic>> evidence;
  final List<Map<String, dynamic>> updates;
  final String status;
  final String? priorRequestStatus;
  final List<Map<String, dynamic>> statusHistory;
  final Map<String, dynamic>? resolution;
  final Map<String, dynamic>? pendingResolution;
  final String? resolutionReference;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? serviceName;
  final String? customerName;
  final String? artisanName;

  String get shortId =>
      id.length >= 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase();

  bool get hasPendingResolution =>
      pendingResolution != null && status == 'pending_execution';

  DateTime? get pendingResolutionExpiresAt {
    final expires = pendingResolution?['expires_at'];
    if (expires is String) return DateTime.tryParse(expires);
    return null;
  }

  factory DisputeDetail.fromJson(Map<String, dynamic> json) {
    return DisputeDetail(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      serviceRequestId: json['service_request_id']?.toString() ?? '',
      paymentId: json['payment_id']?.toString(),
      reporterId: json['reporter_id']?.toString() ?? '',
      reporterRole: json['reporter_role']?.toString() ?? 'customer',
      reporterName: json['reporter_name']?.toString(),
      reason: json['reason']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      urgency: json['urgency']?.toString(),
      evidence: ((json['evidence'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
      updates: ((json['updates'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
      status: json['status']?.toString() ?? 'opened',
      priorRequestStatus: json['prior_request_status']?.toString(),
      statusHistory: ((json['status_history'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
      resolution: json['resolution'] as Map<String, dynamic>?,
      pendingResolution: json['pending_resolution'] as Map<String, dynamic>?,
      resolutionReference: json['resolution_reference']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      serviceName: json['service_name']?.toString(),
      customerName: json['customer_name']?.toString(),
      artisanName: json['artisan_name']?.toString(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

/// A payment summary as returned alongside the dispute.
class DisputePayment {
  const DisputePayment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.commissionRateSnapshot,
    required this.commissionAmount,
    required this.artisanGrossAmount,
    required this.artisanNetAmount,
  });

  final String id;
  final num? amount;
  final String currency;
  final String status;
  final num? commissionRateSnapshot;
  final num? commissionAmount;
  final num? artisanGrossAmount;
  final num? artisanNetAmount;

  factory DisputePayment.fromJson(Map<String, dynamic> json) {
    return DisputePayment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      amount: json['amount'] as num?,
      currency: json['currency']?.toString() ?? 'XAF',
      status: json['status']?.toString() ?? 'held',
      commissionRateSnapshot: json['commission_rate_snapshot'] as num?,
      commissionAmount: json['commission_amount'] as num?,
      artisanGrossAmount: json['artisan_gross_amount'] as num?,
      artisanNetAmount: json['artisan_net_amount'] as num?,
    );
  }
}

/// A full detail response from the show endpoint.
class DisputeDetailResponse {
  const DisputeDetailResponse({
    required this.dispute,
    required this.payment,
    required this.simulationNotice,
  });

  final DisputeDetail dispute;
  final DisputePayment? payment;
  final String? simulationNotice;
}

class AdminDisputeRepository {
  AdminDisputeRepository({
    required this.apiService,
    TokenStorage? tokenStorage,
    http.Client? httpClient,
  })  : _tokenStorage = tokenStorage ?? const TokenStorage(),
        _httpClient = httpClient ?? http.Client();

  final ApiService apiService;
  final TokenStorage _tokenStorage;
  final http.Client _httpClient;

  Future<List<DisputeSummary>> fetchAll({String? status}) async {
    try {
      final endpoint = status == null
          ? '/admin/disputes'
          : '/admin/disputes?status=$status';
      final response = await apiService.authenticatedGet(endpoint);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['disputes'] as List?) ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(DisputeSummary.fromJson)
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load disputes: $e');
    }
  }

  Future<DisputeDetailResponse> fetchDetail(String disputeId) async {
    try {
      final response =
          await apiService.authenticatedGet('/admin/disputes/$disputeId');
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final disputeJson = json['dispute'] as Map<String, dynamic>?;
      if (disputeJson == null) {
        throw const ApiException(
          message: 'Unexpected response shape.',
          statusCode: 500,
        );
      }
      final paymentJson = json['payment'] as Map<String, dynamic>?;
      return DisputeDetailResponse(
        dispute: DisputeDetail.fromJson(disputeJson),
        payment: paymentJson != null
            ? DisputePayment.fromJson(paymentJson)
            : null,
        simulationNotice: json['simulation_notice']?.toString(),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load dispute: $e');
    }
  }

  Future<void> startReview(String id, String notes) =>
      _postNotes(id, 'review', notes);

  Future<void> investigate(String id, String notes) =>
      _postNotes(id, 'investigate', notes);

  Future<void> awaitInformation(String id, String notes) =>
      _postNotes(id, 'awaiting-information', notes);

  Future<void> resolve({
    required String id,
    required String decision,
    required int customerRefundAmount,
    required int artisanGrossRelease,
    required String reason,
    required String resolutionReference,
  }) async {
    try {
      await apiService.authenticatedPost(
        '/admin/disputes/$id/resolve',
        body: {
          'decision': decision,
          'customer_refund_amount': customerRefundAmount,
          'artisan_gross_release': artisanGrossRelease,
          'reason': reason,
          'resolution_reference': resolutionReference,
        },
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to resolve: $e');
    }
  }

  Future<void> confirmResolution(String id) async {
    try {
      await apiService.authenticatedPost(
        '/admin/disputes/$id/confirm-resolution',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to confirm: $e');
    }
  }

  Future<void> cancelResolution(String id, String reason) async {
    try {
      await apiService.authenticatedPost(
        '/admin/disputes/$id/cancel-resolution',
        body: {'reason': reason},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to cancel: $e');
    }
  }

  Future<void> reconcile(String id, String notes) =>
      _postNotes(id, 'reconcile', notes);

  Future<void> _postNotes(String id, String action, String notes) async {
    try {
      await apiService.authenticatedPost(
        '/admin/disputes/$id/$action',
        body: {'notes': notes},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Action failed: $e');
    }
  }

  /// Downloads a piece of evidence as raw bytes.
  Future<({List<int> bytes, String filename})> downloadEvidence({
    required String disputeId,
    required String evidenceId,
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
        '${ApiConstants.baseUrl}/admin/disputes/$disputeId/evidence/$evidenceId',
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
          message: 'Could not load evidence (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }

      final disposition = response.headers['content-disposition'] ?? '';
      final match = RegExp(r'filename="?([^"]+)"?').firstMatch(disposition);
      final filename = match?.group(1) ?? 'evidence';

      return (bytes: response.bodyBytes, filename: filename);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Download failed: $e');
    }
  }
}