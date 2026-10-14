import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';

class AdminAuditLog {
  const AdminAuditLog({
    required this.id,
    required this.eventType,
    required this.actorId,
    required this.subjectType,
    required this.subjectId,
    required this.metadata,
    required this.createdAt,
  });

  final String id;
  final String eventType;
  final String? actorId;
  final String? subjectType;
  final String? subjectId;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  String get shortId => id.length >= 8
      ? id.substring(0, 8)
      : id;

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) {
    return AdminAuditLog(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? '',
      actorId: json['actor_id']?.toString(),
      subjectType: json['subject_type']?.toString(),
      subjectId: json['subject_id']?.toString(),
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? const {},
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

class AdminAuditLogsMeta {
  const AdminAuditLogsMeta({
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

  factory AdminAuditLogsMeta.fromJson(Map<String, dynamic> json) {
    return AdminAuditLogsMeta(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 25,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminAuditLogsResponse {
  const AdminAuditLogsResponse({
    required this.logs,
    required this.meta,
  });

  final List<AdminAuditLog> logs;
  final AdminAuditLogsMeta meta;
}

class AdminAuditLogsFilter {
  const AdminAuditLogsFilter({
    this.eventType,
    this.actorId,
    this.subjectType,
    this.page = 1,
    this.perPage = 25,
  });

  final String? eventType;
  final String? actorId;
  final String? subjectType;
  final int page;
  final int perPage;

  AdminAuditLogsFilter copyWith({
    String? eventType,
    String? actorId,
    String? subjectType,
    int? page,
    int? perPage,
    bool clearEventType = false,
    bool clearActorId = false,
    bool clearSubjectType = false,
  }) {
    return AdminAuditLogsFilter(
      eventType:
          clearEventType ? null : (eventType ?? this.eventType),
      actorId: clearActorId ? null : (actorId ?? this.actorId),
      subjectType:
          clearSubjectType ? null : (subjectType ?? this.subjectType),
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminAuditLogsFilter &&
          runtimeType == other.runtimeType &&
          eventType == other.eventType &&
          actorId == other.actorId &&
          subjectType == other.subjectType &&
          page == other.page &&
          perPage == other.perPage;

  @override
  int get hashCode =>
      eventType.hashCode ^
      actorId.hashCode ^
      subjectType.hashCode ^
      page.hashCode ^
      perPage.hashCode;
}

class AdminAuditLogRepository {
  AdminAuditLogRepository({required this.apiService});

  final ApiService apiService;

  Future<AdminAuditLogsResponse> fetch(
    AdminAuditLogsFilter filter,
  ) async {
    try {
      final params = <String, String>{
        'per_page': filter.perPage.toString(),
        'page': filter.page.toString(),
      };
      if (filter.eventType != null && filter.eventType!.isNotEmpty) {
        params['event_type'] = filter.eventType!;
      }
      if (filter.actorId != null && filter.actorId!.isNotEmpty) {
        params['actor_id'] = filter.actorId!;
      }
      if (filter.subjectType != null &&
          filter.subjectType!.isNotEmpty) {
        params['subject_type'] = filter.subjectType!;
      }

      final query = params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response =
          await apiService.authenticatedGet('/admin/audit-logs?$query');
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['audit_logs'] as List?) ?? const [];
      final meta = (json['meta'] as Map<String, dynamic>?) ?? const {};

      return AdminAuditLogsResponse(
        logs: list
            .whereType<Map<String, dynamic>>()
            .map(AdminAuditLog.fromJson)
            .toList(growable: false),
        meta: AdminAuditLogsMeta.fromJson(meta),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load audit logs: $e');
    }
  }
}