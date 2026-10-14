import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/customer_conversations_repository.dart';
import '../../domain/models/conversation_summary.dart';

final customerConversationsRepositoryProvider =
    Provider<CustomerConversationsRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return CustomerConversationsRepository(apiService: api);
});

final customerConversationsProvider =
    FutureProvider.autoDispose<List<ConversationSummary>>((ref) {
  final repo = ref.watch(customerConversationsRepositoryProvider);
  return repo.list();
});