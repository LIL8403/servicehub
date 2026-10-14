import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:servicehub_frontend/core/api/api_exception.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/message.dart';
import '../providers/conversation_providers.dart';

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({
    super.key,
    required this.requestId,
    required this.artisanName,
    this.artisanTitle,
  });

  final String requestId;
  final String artisanName;
  final String? artisanTitle;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<File> _pendingAttachments = [];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _inputController.text.trim();
    if (body.isEmpty && _pendingAttachments.isEmpty) return;

    final conversationAsync = ref
        .read(conversationProvider(widget.requestId))
        .valueOrNull;
    final conversationId = conversationAsync?.id;
    if (conversationId == null) return;

    final ok = await ref
        .read(sendMessageProvider.notifier)
        .send(
          conversationId: conversationId,
          body: body,
          attachments: List.from(_pendingAttachments),
        );

    if (!mounted) return;

    if (ok) {
      _inputController.clear();
      setState(() => _pendingAttachments.clear());
      ref.invalidate(conversationMessagesProvider(conversationId));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } else {
      final err =
          ref.read(sendMessageProvider).errorMessage ??
          'Could not send. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _pendingAttachments.addAll(picked.map((x) => File(x.path)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversationAsync = ref.watch(conversationProvider(widget.requestId));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(
              artisanName: widget.artisanName,
              artisanTitle: widget.artisanTitle,
              onBack: () => context.pop(),
            ),
            _ContextStrip(requestId: widget.requestId),
            Expanded(
              child: conversationAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) {
                  // A 404 typically means the underlying service request was
                  // deleted. Show a clean message instead of the raw exception.
                  final isMissing =
                      err is ApiException && err.statusCode == 404;
                  return _ErrorView(
                    message: isMissing
                        ? 'This conversation is no longer available.'
                        : err.toString(),
                    onRetry: isMissing
                        ? null
                        : () => ref.invalidate(
                            conversationProvider(widget.requestId),
                          ),
                  );
                },
                data: (conversation) {
                  final messagesAsync = ref.watch(
                    conversationMessagesProvider(conversation.id),
                  );
                  return messagesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => _ErrorView(
                      message: err.toString(),
                      onRetry: () => ref.invalidate(
                        conversationMessagesProvider(conversation.id),
                      ),
                    ),
                    data: (messages) => _MessageList(
                      messages: messages,
                      currentUserId:
                          ref.watch(authStateProvider).user?.id ?? '',
                      scrollController: _scrollController,
                    ),
                  );
                },
              ),
            ),
            _InputBar(
              controller: _inputController,
              pendingAttachments: _pendingAttachments,
              isSending: ref.watch(sendMessageProvider).isSending,
              onSend: _send,
              onAttach: _pickAttachment,
              onRemoveAttachment: (index) =>
                  setState(() => _pendingAttachments.removeAt(index)),
              artisanName: widget.artisanName,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.artisanName,
    required this.artisanTitle,
    required this.onBack,
  });

  final String artisanName;
  final String? artisanTitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardLight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  artisanName,
                  style: AppTypography.h4.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (artisanTitle != null)
                  Text(
                    artisanTitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _ContextStrip extends StatelessWidget {
  const _ContextStrip({required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    final short = requestId.length <= 6
        ? requestId.toUpperCase()
        : requestId.substring(requestId.length - 6).toUpperCase();

    return Container(
      width: double.infinity,
      color: AppColors.bgLight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.build_outlined,
            size: 14,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Ref: $short',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
  });

  final List<ChatMessage> messages;
  final String currentUserId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const _EmptyConversation();
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isMine = msg.senderId == currentUserId;
        return _MessageBubble(message: msg, isMine: isMine);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine ? AppColors.primary : AppColors.cream;
    final textColor = isMine ? AppColors.textInverse : AppColors.primary;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: Radius.circular(isMine ? 12 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 12),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: radius,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasBody)
                    Text(
                      message.body,
                      style: AppTypography.bodyMedium.copyWith(
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                  for (final attachment in message.attachments)
                    Padding(
                      padding: EdgeInsets.only(top: message.hasBody ? 8 : 0),
                      child: _AttachmentTile(
                        attachment: attachment,
                        isMine: isMine,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (message.createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _timeLabel(message.createdAt!),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment, required this.isMine});

  final MessageAttachment attachment;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final fg = isMine ? AppColors.textInverse : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isMine ? Colors.white : AppColors.primary).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attachment.isImage ? Icons.image_outlined : Icons.picture_as_pdf,
            size: 20,
            color: fg,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: AppTypography.bodySmall.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  attachment.sizeLabel,
                  style: AppTypography.caption.copyWith(
                    color: fg.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Start the conversation',
              style: AppTypography.h3.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ask a question or share additional details about your request.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.pendingAttachments,
    required this.isSending,
    required this.onSend,
    required this.onAttach,
    required this.onRemoveAttachment,
    required this.artisanName,
  });

  final TextEditingController controller;
  final List<File> pendingAttachments;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final ValueChanged<int> onRemoveAttachment;
  final String artisanName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardLight,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pendingAttachments.isNotEmpty) ...[
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pendingAttachments.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: AppRadii.borderMd,
                          color: AppColors.bgLight,
                          image: DecorationImage(
                            image: FileImage(pendingAttachments[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => onRemoveAttachment(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: AppColors.textInverse,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.textMuted,
                ),
                onPressed: isSending ? null : onAttach,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  enabled: !isSending,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message $artisanName...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.bgLight,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9999),
                      borderSide: const BorderSide(
                        color: AppColors.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9999),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: isSending ? null : onSend,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSending ? AppColors.disabledBg : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: isSending
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textInverse,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.arrow_upward,
                          size: 18,
                          color: AppColors.textInverse,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
