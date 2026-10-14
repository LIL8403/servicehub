import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/api/token_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';

/// Handles the customer-side conversation with the artisan.
///
/// All endpoints live under `/api/customer/...` and require the auth
/// token. The repository uses the shared [ApiService] for JSON calls
/// and a direct multipart `http` call for the message-send endpoint,
/// because `ApiService` intentionally only supports JSON bodies.
class ConversationRepository {
  ConversationRepository({
    required this.apiService, 
    TokenStorage? tokenStorage,
    })
    : _tokenStorage = tokenStorage ?? const TokenStorage();

  final ApiService apiService;
  final TokenStorage _tokenStorage;

  /// Fetches the conversation shell for a given service request.
  /// The backend creates the conversation lazily on first access.
  Future<Conversation> fetchConversation(String requestId) async {
    if (requestId.isEmpty) {
      throw const ApiException(
        message: 'A request ID is required to open the conversation.',
        statusCode: 400,
      );
    }

    try {
      final response = await apiService.authenticatedGet(
        '/customer/service-requests/$requestId/conversation',
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final conversation = json['conversation'] as Map<String, dynamic>?;

      if (conversation == null) {
        throw const ApiException(
          message: 'The server returned an unexpected response format.',
          statusCode: 500,
        );
      }

      return Conversation.fromJson(conversation);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to open conversation: $e');
    }
  }

  /// Fetches all messages in a conversation, oldest first.
  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    if (conversationId.isEmpty) {
      throw const ApiException(
        message: 'A conversation ID is required to fetch messages.',
        statusCode: 400,
      );
    }

    try {
      final response = await apiService.authenticatedGet(
        '/customer/conversations/$conversationId/messages',
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['messages'] as List?) ?? const [];

      return list
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load messages: $e');
    }
  }

  /// Sends a message. The backend accepts a text body, attachments, or
  /// both. This call uses multipart because attachments are optional
  /// but the endpoint's validation expects the same shape either way.
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String body,
    List<File> attachments = const [],
  }) async {
    if (conversationId.isEmpty) {
      throw const ApiException(
        message: 'A conversation ID is required to send a message.',
        statusCode: 400,
      );
    }
    if (body.trim().isEmpty && attachments.isEmpty) {
      throw const ApiException(
        message: 'A message must have text or at least one attachment.',
        statusCode: 400,
      );
    }

    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Authentication token not found.',
        statusCode: 401,
      );
    }

    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/customer/conversations/$conversationId/messages',
      );

      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token';

      if (body.trim().isNotEmpty) {
        request.fields['body'] = body.trim();
      }

      for (final file in attachments.take(5)) {
        request.files.add(
          await http.MultipartFile.fromPath('attachments[]', file.path),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message:
              _extractError(response.body) ??
              'Failed to send message (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final message = json['message'] as Map<String, dynamic>?;

      if (message == null) {
        throw const ApiException(
          message: 'The server returned an unexpected response format.',
          statusCode: 500,
        );
      }

      return ChatMessage.fromJson(message);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to send message: $e');
    }
  }

  /// Fetches the raw bytes of an attachment. The caller renders or
  /// saves them. Bytes are not cached — the UI layer holds them in a
  /// provider-scoped cache if needed.
  Future<Uint8List> downloadAttachment({
    required String conversationId,
    required String messageId,
    required String attachmentId,
  }) async {
    try {
      final response = await apiService.authenticatedGet(
        '/customer/conversations/$conversationId/messages/$messageId/attachments/$attachmentId',
      );
      return Uint8List.fromList(response.bodyBytes);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to download attachment: $e');
    }
  }

  String? _extractError(String body) {
    if (body.isEmpty) return null;
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        if (json['message'] is String) return json['message'] as String;
        if (json['error'] is Map && json['error']['message'] is String) {
          return json['error']['message'] as String;
        }
      }
    } catch (_) {
      // Ignore — return the fallback.
    }
    return null;
  }
}
