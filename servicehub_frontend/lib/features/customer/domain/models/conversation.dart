import 'package:flutter/foundation.dart';

/// Mirrors the payload returned by
/// `GET /api/customer/service-requests/{id}/conversation`.
@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.serviceRequestId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String serviceRequestId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id']?.toString() ?? '',
      serviceRequestId: json['service_request_id']?.toString() ?? '',
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