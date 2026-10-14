import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';

class AdminServiceRequest {
  const AdminServiceRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.serviceId,
    required this.serviceName,
    required this.artisanProfileId,
    required this.artisanName,
    required this.description,
    required this.status,
    required this.locationLabel,
    required this.formattedAddress,
    required this.preferredSchedule,
    required this.urgency,
    required this.noArtisanReason,
    required this.matchingAttempts,
    required this.aiAssistEnabled,
    required this.imageAttachments,
    required this.statusHistory,
    required this.selectionHistory,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String customerId;
  final String? customerName;
  final String serviceId;
  final String? serviceName;
  final String? artisanProfileId;
  final String? artisanName;
  final String description;
  final String status;
  final String? locationLabel;
  final String? formattedAddress;
  final Map<String, dynamic>? preferredSchedule;
  final String? urgency;
  final String? noArtisanReason;
  final int matchingAttempts;
  final bool aiAssistEnabled;
  final List<Map<String, dynamic>> imageAttachments;
  final List<Map<String, dynamic>> statusHistory;
  final List<Map<String, dynamic>> selectionHistory;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Last 6 characters of the id, uppercased. Used in the "REQ #..."
  /// badge.
  String get shortId => id.length >= 6
      ? id.substring(id.length - 6).toUpperCase()
      : id.toUpperCase();

  String get customerInitials {
    final n = customerName ?? '';
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory AdminServiceRequest.fromJson(Map<String, dynamic> json) {
    return AdminServiceRequest(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString(),
      serviceId: json['service_id']?.toString() ?? '',
      serviceName: json['service_name']?.toString(),
      artisanProfileId: json['artisan_profile_id']?.toString(),
      artisanName: json['artisan_name']?.toString(),
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'created',
      locationLabel: json['location_label']?.toString(),
      formattedAddress: json['formatted_address']?.toString(),
      preferredSchedule:
          json['preferred_schedule'] as Map<String, dynamic>?,
      urgency: json['urgency']?.toString(),
      noArtisanReason: json['no_artisan_reason']?.toString(),
      matchingAttempts:
          (json['matching_attempts'] as num?)?.toInt() ?? 0,
      aiAssistEnabled: json['ai_assist_enabled'] == true,
      imageAttachments: ((json['image_attachments'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
      statusHistory: ((json['status_history'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
      selectionHistory:
          ((json['selection_history'] as List?) ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

class AdminServiceRequestsMeta {
  const AdminServiceRequestsMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  int get from => total == 0 ? 0 : ((currentPage - 1) * perPage) + 1;
  int get to {
    if (total == 0) return 0;
    final end = currentPage * perPage;
    return end > total ? total : end;
  }

  factory AdminServiceRequestsMeta.fromJson(Map<String, dynamic> json) {
    return AdminServiceRequestsMeta(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 25,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminServiceRequestsResponse {
  const AdminServiceRequestsResponse({
    required this.requests,
    required this.meta,
  });

  final List<AdminServiceRequest> requests;
  final AdminServiceRequestsMeta meta;
}

class AdminServiceRequestsFilter {
  const AdminServiceRequestsFilter({
    this.status,
    this.serviceId,
    this.page = 1,
    this.perPage = 25,
  });

  final String? status;
  final String? serviceId;
  final int page;
  final int perPage;

  AdminServiceRequestsFilter copyWith({
    String? status,
    String? serviceId,
    int? page,
    int? perPage,
    bool clearStatus = false,
    bool clearServiceId = false,
  }) {
    return AdminServiceRequestsFilter(
      status: clearStatus ? null : (status ?? this.status),
      serviceId: clearServiceId ? null : (serviceId ?? this.serviceId),
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminServiceRequestsFilter &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          serviceId == other.serviceId &&
          page == other.page &&
          perPage == other.perPage;

  @override
  int get hashCode =>
      status.hashCode ^
      serviceId.hashCode ^
      page.hashCode ^
      perPage.hashCode;
}

class AdminServiceRequestRepository {
  AdminServiceRequestRepository({required this.apiService});

  final ApiService apiService;

  Future<AdminServiceRequestsResponse> fetch(
    AdminServiceRequestsFilter filter,
  ) async {
    try {
      final params = <String, String>{
        'per_page': filter.perPage.toString(),
        'page': filter.page.toString(),
      };
      if (filter.status != null && filter.status!.isNotEmpty) {
        params['status'] = filter.status!;
      }
      if (filter.serviceId != null && filter.serviceId!.isNotEmpty) {
        params['service_id'] = filter.serviceId!;
      }

      final query = params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await apiService
          .authenticatedGet('/admin/service-requests?$query');
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['service_requests'] as List?) ?? const [];
      final meta = (json['meta'] as Map<String, dynamic>?) ?? const {};

      return AdminServiceRequestsResponse(
        requests: list
            .whereType<Map<String, dynamic>>()
            .map(AdminServiceRequest.fromJson)
            .toList(growable: false),
        meta: AdminServiceRequestsMeta.fromJson(meta),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load service requests: $e');
    }
  }
}