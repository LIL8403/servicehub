import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../domain/models/conversation_summary.dart';

class CustomerConversationsRepository {
  CustomerConversationsRepository({required this.apiService});

  final ApiService apiService;

  Future<List<ConversationSummary>> list() async {
    try {
      final response = await apiService.authenticatedGet(
        '/customer/conversations',
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['conversations'] as List?) ?? const [];

      return list
          .whereType<Map<String, dynamic>>()
          .map(ConversationSummary.fromJson)
          .where((c) => c.id.isNotEmpty)
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load conversations: $e');
    }
  }
}