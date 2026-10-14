import 'package:flutter/foundation.dart';

/// A single chat message between the customer and the artisan.
///
/// Matches the payload returned by
/// `GET /api/customer/conversations/{id}/messages`.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.attachments,
    this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final List<MessageAttachment> attachments;
  final DateTime? createdAt;

  bool get hasBody => body.trim().isNotEmpty;
  bool get hasAttachments => attachments.isNotEmpty;

  /// True when the message is empty (no body and no attachments).
  /// Should never happen in practice — the backend requires one or
  /// the other — but this guards the UI against a malformed response.
  bool get isEmpty => !hasBody && !hasAttachments;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawAttachments = (json['attachments'] as List?) ?? const [];
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: _parseDate(json['created_at']),
      attachments: rawAttachments
          .whereType<Map<String, dynamic>>()
          .map(MessageAttachment.fromJson)
          .toList(growable: false),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

@immutable
class MessageAttachment {
  const MessageAttachment({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.size,
  });

  final String id;
  final String name;
  final String mimeType;
  final int size;

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';

  String get sizeLabel {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(0)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'attachment',
      mimeType: json['mime_type']?.toString() ?? 'application/octet-stream',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}