import 'package:flutter/foundation.dart';

@immutable
class PayoutRecord {
  const PayoutRecord({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.grossAmount,
    required this.commissionAmount,
    required this.requestId,
    required this.serviceName,
    required this.customerFirstName,
    this.createdAt,
    this.paidAt,
  });

  final String id;
  final int amount;
  final String currency;
  final String status;
  final int grossAmount;
  final int commissionAmount;
  final String requestId;
  final String serviceName;
  final String customerFirstName;
  final DateTime? createdAt;
  final DateTime? paidAt;

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'initiated' || status == 'processing';
  bool get isFailed => status == 'failed';

  factory PayoutRecord.fromJson(Map<String, dynamic> json) {
    return PayoutRecord(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'XAF',
      status: json['status']?.toString() ?? 'initiated',
      grossAmount: (json['gross_amount'] as num?)?.toInt() ?? 0,
      commissionAmount: (json['commission_amount'] as num?)?.toInt() ?? 0,
      requestId: json['request_id']?.toString() ?? '',
      serviceName: json['service_name']?.toString() ?? 'Service',
      customerFirstName: json['customer_first_name']?.toString() ?? '',
      createdAt: _parse(json['created_at']),
      paidAt: _parse(json['paid_at']),
    );
  }

  static DateTime? _parse(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

@immutable
class PayoutPage {
  const PayoutPage({
    required this.payouts,
    required this.total,
    required this.page,
    required this.perPage,
  });

  final List<PayoutRecord> payouts;
  final int total;
  final int page;
  final int perPage;

  bool get hasMore => page * perPage < total;

  factory PayoutPage.fromJson(Map<String, dynamic> json) {
    final list = (json['payouts'] as List?) ?? const [];
    return PayoutPage(
      payouts: list
          .whereType<Map<String, dynamic>>()
          .map(PayoutRecord.fromJson)
          .toList(growable: false),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 20,
    );
  }
}
