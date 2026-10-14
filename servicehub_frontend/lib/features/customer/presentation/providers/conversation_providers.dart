import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ConversationRepository(apiService: api);
});

/// Fetches the conversation shell for a request. The family arg is the
/// service request's id.
final conversationProvider =
    FutureProvider.autoDispose.family<Conversation, String>((ref, requestId) {
  final repo = ref.watch(conversationRepositoryProvider);
  return repo.fetchConversation(requestId);
});

/// Fetches messages for a conversation id.
final conversationMessagesProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, conversationId) {
  final repo = ref.watch(conversationRepositoryProvider);
  return repo.fetchMessages(conversationId);
});

/// Manages the in-flight send-message state. Messages are optimistically
/// appended to an in-memory list so the UI feels responsive, then the
/// provider is invalidated when the send succeeds.
class SendMessageState {
  const SendMessageState({
    this.isSending = false,
    this.errorMessage,
    this.lastSent,
  });

  final bool isSending;
  final String? errorMessage;
  final ChatMessage? lastSent;

  SendMessageState copyWith({
    bool? isSending,
    String? errorMessage,
    ChatMessage? lastSent,
    bool clearErrors = false,
  }) {
    return SendMessageState(
      isSending: isSending ?? this.isSending,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      lastSent: lastSent ?? this.lastSent,
    );
  }
}

class SendMessageNotifier extends StateNotifier<SendMessageState> {
  SendMessageNotifier(this._ref) : super(const SendMessageState());

  final Ref _ref;

  Future<bool> send({
    required String conversationId,
    required String body,
    List<File> attachments = const [],
  }) async {
    state = state.copyWith(isSending: true, clearErrors: true);

    try {
      final sent = await _ref
          .read(conversationRepositoryProvider)
          .sendMessage(
            conversationId: conversationId,
            body: body,
            attachments: attachments,
          );

      if (!mounted) return true;
      state = state.copyWith(isSending: false, lastSent: sent);
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSending: false,
        errorMessage: e.firstErrorMessage,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        isSending: false,
        errorMessage: 'Could not send the message.',
      );
      return false;
    }
  }

  void reset() => state = const SendMessageState();
}

final sendMessageProvider =
    StateNotifierProvider.autoDispose<SendMessageNotifier, SendMessageState>(
  (ref) => SendMessageNotifier(ref),
);