import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';

class AdminPayout {
  const AdminPayout({
    required this.id,
    required this.paymentId,
    required this.serviceRequestId,
    required this.artisanProfileId,
    required this.artisanName,
    required this.amount,
    required this.grossAmount,
    required this.commissionAmount,
    required this.currency,
    required this.status,
    required this.provider,
    required this.providerReference,
    required this.externalReference,
    required this.events,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String paymentId;
  final String serviceRequestId;
  final String artisanProfileId;
  final String? artisanName;
  final int amount;
  final int? grossAmount;
  final int? commissionAmount;
  final String currency;
  final String status;
  final String? provider;
  final String? providerReference;
  final String? externalReference;
  final List<Map<String, dynamic>> events;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get shortId =>
      id.length >= 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();

  String get initials {
    final n = artisanName ?? '';
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory AdminPayout.fromJson(Map<String, dynamic> json) {
    return AdminPayout(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      paymentId: json['payment_id']?.toString() ?? '',
      serviceRequestId: json['service_request_id']?.toString() ?? '',
      artisanProfileId: json['artisan_profile_id']?.toString() ?? '',
      artisanName: json['artisan_name']?.toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      grossAmount: (json['gross_amount'] as num?)?.toInt(),
      commissionAmount: (json['commission_amount'] as num?)?.toInt(),
      currency: json['currency']?.toString() ?? 'XAF',
      status: json['status']?.toString() ?? 'initiated',
      provider: json['provider']?.toString(),
      providerReference: json['provider_reference']?.toString(),
      externalReference: json['external_reference']?.toString(),
      events: ((json['events'] as List?) ?? const [])
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

class AdminPayoutsMeta {
  const AdminPayoutsMeta({
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

  factory AdminPayoutsMeta.fromJson(Map<String, dynamic> json) {
    return AdminPayoutsMeta(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 25,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminPayoutsResponse {
  const AdminPayoutsResponse({required this.payouts, required this.meta});

  final List<AdminPayout> payouts;
  final AdminPayoutsMeta meta;
}

class AdminPayoutsFilter {
  const AdminPayoutsFilter({
    this.status,
    this.provider,
    this.page = 1,
    this.perPage = 25,
  });

  final String? status;
  final String? provider;
  final int page;
  final int perPage;

  AdminPayoutsFilter copyWith({
    String? status,
    String? provider,
    int? page,
    int? perPage,
    bool clearStatus = false,
    bool clearProvider = false,
  }) {
    return AdminPayoutsFilter(
      status: clearStatus ? null : (status ?? this.status),
      provider: clearProvider ? null : (provider ?? this.provider),
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminPayoutsFilter &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          provider == other.provider &&
          page == other.page &&
          perPage == other.perPage;

  @override
  int get hashCode =>
      status.hashCode ^
      provider.hashCode ^
      page.hashCode ^
      perPage.hashCode;
}

class AdminPayoutRepository {
  AdminPayoutRepository({required this.apiService});

  final ApiService apiService;

  Future<AdminPayoutsResponse> fetch(AdminPayoutsFilter filter) async {
    try {
      final params = <String, String>{
        'per_page': filter.perPage.toString(),
        'page': filter.page.toString(),
      };
      if (filter.status != null && filter.status!.isNotEmpty) {
        params['status'] = filter.status!;
      }
      if (filter.provider != null && filter.provider!.isNotEmpty) {
        params['provider'] = filter.provider!;
      }

      final query = params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response =
          await apiService.authenticatedGet('/admin/payouts?$query');
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['payouts'] as List?) ?? const [];
      final meta = (json['meta'] as Map<String, dynamic>?) ?? const {};

      return AdminPayoutsResponse(
        payouts: list
            .whereType<Map<String, dynamic>>()
            .map(AdminPayout.fromJson)
            .toList(growable: false),
        meta: AdminPayoutsMeta.fromJson(meta),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load payouts: $e');
    }
  }
}