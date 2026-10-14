import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';

class AdminPayment {
  const AdminPayment({
    required this.id,
    required this.serviceRequestId,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.currency,
    required this.status,
    required this.provider,
    required this.providerChannel,
    required this.providerReference,
    required this.externalReference,
    required this.commissionRateSnapshot,
    required this.commissionAmount,
    required this.artisanGrossAmount,
    required this.artisanNetAmount,
    required this.events,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String serviceRequestId;
  final String customerId;
  final String? customerName;
  final int amount;
  final String currency;
  final String status;
  final String? provider;
  final String? providerChannel;
  final String? providerReference;
  final String? externalReference;
  final double? commissionRateSnapshot;
  final int? commissionAmount;
  final int? artisanGrossAmount;
  final int? artisanNetAmount;
  final List<Map<String, dynamic>> events;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get shortId =>
      id.length >= 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();

  factory AdminPayment.fromJson(Map<String, dynamic> json) {
    return AdminPayment(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      serviceRequestId: json['service_request_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'XAF',
      status: json['status']?.toString() ?? 'initiated',
      provider: json['provider']?.toString(),
      providerChannel: json['provider_channel']?.toString(),
      providerReference: json['provider_reference']?.toString(),
      externalReference: json['external_reference']?.toString(),
      commissionRateSnapshot:
          (json['commission_rate_snapshot'] as num?)?.toDouble(),
      commissionAmount: (json['commission_amount'] as num?)?.toInt(),
      artisanGrossAmount: (json['artisan_gross_amount'] as num?)?.toInt(),
      artisanNetAmount: (json['artisan_net_amount'] as num?)?.toInt(),
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

class AdminPaymentsMeta {
  const AdminPaymentsMeta({
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

  factory AdminPaymentsMeta.fromJson(Map<String, dynamic> json) {
    return AdminPaymentsMeta(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 25,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminPaymentsResponse {
  const AdminPaymentsResponse({required this.payments, required this.meta});

  final List<AdminPayment> payments;
  final AdminPaymentsMeta meta;
}

class AdminPaymentsFilter {
  const AdminPaymentsFilter({
    this.status,
    this.provider,
    this.page = 1,
    this.perPage = 25,
  });

  final String? status;
  final String? provider;
  final int page;
  final int perPage;

  AdminPaymentsFilter copyWith({
    String? status,
    String? provider,
    int? page,
    int? perPage,
    bool clearStatus = false,
    bool clearProvider = false,
  }) {
    return AdminPaymentsFilter(
      status: clearStatus ? null : (status ?? this.status),
      provider: clearProvider ? null : (provider ?? this.provider),
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminPaymentsFilter &&
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

class AdminPaymentRepository {
  AdminPaymentRepository({required this.apiService});

  final ApiService apiService;

  Future<AdminPaymentsResponse> fetch(AdminPaymentsFilter filter) async {
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
          await apiService.authenticatedGet('/admin/payments?$query');
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['payments'] as List?) ?? const [];
      final meta = (json['meta'] as Map<String, dynamic>?) ?? const {};

      return AdminPaymentsResponse(
        payments: list
            .whereType<Map<String, dynamic>>()
            .map(AdminPayment.fromJson)
            .toList(growable: false),
        meta: AdminPaymentsMeta.fromJson(meta),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load payments: $e');
    }
  }
}