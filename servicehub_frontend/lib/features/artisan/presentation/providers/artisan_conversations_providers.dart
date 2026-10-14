import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../customer/domain/models/conversation_summary.dart';
import '../../data/repositories/artisan_conversations_repository.dart';

final artisanConversationsRepositoryProvider =
    Provider<ArtisanConversationsRepository>((ref) {
      final api = ref.watch(apiServiceProvider);
      return ArtisanConversationsRepository(apiService: api);
    });

final artisanConversationsProvider =
    FutureProvider.autoDispose<List<ConversationSummary>>((ref) {
      return ref.watch(artisanConversationsRepositoryProvider).list();
    });

/// Sum of unread counts across all artisan conversations. Used for the
/// badge on the Messages tab in the artisan shell.
final artisanUnreadCountProvider = Provider.autoDispose<int>((ref) {
  final async = ref.watch(artisanConversationsProvider);
  return async.maybeWhen(
    data: (list) => list.fold<int>(0, (sum, c) => sum + c.unreadCount),
    orElse: () => 0,
  );
});
