import 'package:flutter/foundation.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

@immutable
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.serviceRequestId,
    required this.unreadCount,
    this.artisan,
    this.service,
    this.lastMessage,
    this.updatedAt,
  });

  final String id;
  final String serviceRequestId;
  final int unreadCount;
  final ConversationArtisan? artisan;
  final ConversationService? service;
  final ConversationLastMessage? lastMessage;
  final DateTime? updatedAt;

  DateTime get sortDate =>
      lastMessage?.createdAt ?? updatedAt ?? DateTime.now();

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    // The other party appears as `artisan` on the customer side and
    // as `customer` on the artisan side. Both carry the same shape.
    final counterpartyJson =
        (json['artisan'] as Map<String, dynamic>?) ??
        (json['customer'] as Map<String, dynamic>?);
    final serviceJson = json['service'] as Map<String, dynamic>?;
    final lastJson = json['last_message'] as Map<String, dynamic>?;

    return ConversationSummary(
      id: json['id']?.toString() ?? '',
      serviceRequestId: json['service_request_id']?.toString() ?? '',
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      artisan: counterpartyJson != null
          ? ConversationArtisan.fromJson(counterpartyJson)
          : null,
      service: serviceJson != null
          ? ConversationService.fromJson(serviceJson)
          : null,
      lastMessage: lastJson != null
          ? ConversationLastMessage.fromJson(lastJson)
          : null,
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}

@immutable
class ConversationArtisan {
  const ConversationArtisan({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.hasPhoto,
  });

  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final bool hasPhoto;

  factory ConversationArtisan.fromJson(Map<String, dynamic> json) {
    return ConversationArtisan(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      hasPhoto: json['has_photo'] == true,
    );
  }
}

@immutable
class ConversationService {
  const ConversationService({required this.id, required this.name});

  final String id;
  final String name;

  factory ConversationService.fromJson(Map<String, dynamic> json) {
    return ConversationService(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

@immutable
class ConversationLastMessage {
  const ConversationLastMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.attachmentsCount,
    this.createdAt,
    this.readAt,
  });

  final String id;
  final String senderId;
  final String body;
  final int attachmentsCount;
  final DateTime? createdAt;
  final DateTime? readAt;

  bool get hasAttachments => attachmentsCount > 0;

  String get preview {
    if (body.trim().isNotEmpty) return body.trim();
    if (hasAttachments) {
      return attachmentsCount == 1 ? 'Photo' : '$attachmentsCount photos';
    }
    return 'No message yet';
  }

  factory ConversationLastMessage.fromJson(Map<String, dynamic> json) {
    return ConversationLastMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      attachmentsCount: (json['attachments_count'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at']),
      readAt: _parseDate(json['read_at']),
    );
  }
}
