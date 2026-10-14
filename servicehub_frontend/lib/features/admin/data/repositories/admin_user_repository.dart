import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';

/// A user as returned by the admin users endpoint.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.roles,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final List<String> roles;

  /// 'active' or 'suspended'.
  final String status;
  final DateTime? createdAt;

  /// The best identifier to show under the name: email if present,
  /// else phone.
  String get contactLine {
    if (email.isNotEmpty) return email;
    if (phone.isNotEmpty) return phone;
    return '—';
  }

  bool get isActive => status.toLowerCase() == 'active';
  bool get isSuspended => status.toLowerCase() == 'suspended';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isEmpty
          ? '?'
          : parts.first[0].toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    final List<String> roles;
    if (rawRoles is List) {
      roles = rawRoles.map((e) => e.toString()).toList(growable: false);
    } else {
      roles = const [];
    }

    return AdminUser(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '—',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      roles: roles,
      status: json['status']?.toString() ?? 'active',
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

/// Pagination metadata returned by the endpoint.
class AdminUsersMeta {
  const AdminUsersMeta({
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

  factory AdminUsersMeta.fromJson(Map<String, dynamic> json) {
    return AdminUsersMeta(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 25,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A page of users with its metadata. Named `Response` to avoid
/// clashing with the `AdminUsersPage` widget class.
class AdminUsersResponse {
  const AdminUsersResponse({required this.users, required this.meta});

  final List<AdminUser> users;
  final AdminUsersMeta meta;
}

/// The filter set applied to a users query.
class AdminUsersFilter {
  const AdminUsersFilter({
    this.search,
    this.role,
    this.status,
    this.page = 1,
    this.perPage = 25,
  });

  final String? search;
  final String? role;
  final String? status;
  final int page;
  final int perPage;

  AdminUsersFilter copyWith({
    String? search,
    String? role,
    String? status,
    int? page,
    int? perPage,
    bool clearSearch = false,
    bool clearRole = false,
    bool clearStatus = false,
  }) {
    return AdminUsersFilter(
      search: clearSearch ? null : (search ?? this.search),
      role: clearRole ? null : (role ?? this.role),
      status: clearStatus ? null : (status ?? this.status),
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUsersFilter &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          role == other.role &&
          status == other.status &&
          page == other.page &&
          perPage == other.perPage;

  @override
  int get hashCode =>
      search.hashCode ^
      role.hashCode ^
      status.hashCode ^
      page.hashCode ^
      perPage.hashCode;
}

class AdminUserRepository {
  AdminUserRepository({required this.apiService});

  final ApiService apiService;

  Future<AdminUsersResponse> fetch(AdminUsersFilter filter) async {
    try {
      final params = <String, String>{};
      if (filter.search != null && filter.search!.isNotEmpty) {
        params['search'] = filter.search!;
      }
      if (filter.role != null && filter.role!.isNotEmpty) {
        params['role'] = filter.role!;
      }
      if (filter.status != null && filter.status!.isNotEmpty) {
        params['status'] = filter.status!;
      }
      params['per_page'] = filter.perPage.toString();
      params['page'] = filter.page.toString();

      final query = params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final endpoint = '/admin/users?$query';

      final response = await apiService.authenticatedGet(endpoint);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final usersJson = (json['users'] as List?) ?? const [];
      final metaJson = (json['meta'] as Map<String, dynamic>?) ?? const {};

      return AdminUsersResponse(
        users: usersJson
            .whereType<Map<String, dynamic>>()
            .map(AdminUser.fromJson)
            .toList(growable: false),
        meta: AdminUsersMeta.fromJson(metaJson),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load users: $e');
    }
  }

  Future<void> updateStatus({
    required String userId,
    required String status,
    required String reason,
  }) async {
    try {
      await apiService.authenticatedPatch(
        '/admin/users/$userId/status',
        body: {
          'status': status,
          'reason': reason,
        },
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to update status: $e');
    }
  }
}