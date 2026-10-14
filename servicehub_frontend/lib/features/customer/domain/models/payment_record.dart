import 'package:flutter/foundation.dart';

@immutable
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.serviceRequestId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.channel,
    required this.createdAt,
    this.updatedAt,
    this.serviceName,
    this.artisanName,
    this.artisanFirstName,
    this.requestReference,
  });

  final String id;
  final String serviceRequestId;
  final double amount;
  final String currency;
  final String status;
  final String? channel;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? serviceName;
  final String? artisanName;
  final String? artisanFirstName;
  final String? requestReference;

  String get channelLabel {
    switch ((channel ?? '').toLowerCase()) {
      case 'mtn':
        return 'MTN Mobile Money';
      case 'orange':
        return 'Orange Money';
      default:
        return 'Mobile Money';
    }
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'initiated':
        return 'Initiated';
      case 'processing':
        return 'Processing';
      case 'held':
        return 'In escrow';
      case 'releasing':
        return 'Releasing';
      case 'released':
        return 'Released';
      case 'refunding':
        return 'Refunding';
      case 'refunded':
        return 'Refunded';
      case 'partially_refunded':
        return 'Partially refunded';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      case 'disputed':
        return 'Disputed';
      case 'under_review':
        return 'Under review';
      default:
        return status;
    }
  }

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>?;
    final artisan = json['artisan'] as Map<String, dynamic>?;

    return PaymentRecord(
      id: json['id']?.toString() ?? '',
      serviceRequestId: json['service_request_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'XAF',
      status: json['status']?.toString() ?? 'unknown',
      channel: json['provider_channel']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      serviceName: service?['name']?.toString(),
      artisanName: artisan?['name']?.toString(),
      artisanFirstName: artisan?['first_name']?.toString(),
      requestReference: json['request_reference']?.toString(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}