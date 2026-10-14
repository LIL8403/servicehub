import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../../customer/domain/models/conversation_summary.dart';
import '../providers/artisan_conversations_providers.dart';

class ArtisanMessagesTab extends ConsumerStatefulWidget {
  const ArtisanMessagesTab({super.key});

  @override
  ConsumerState<ArtisanMessagesTab> createState() => _ArtisanMessagesTabState();
}

class _ArtisanMessagesTabState extends ConsumerState<ArtisanMessagesTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(artisanConversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Messages',
          style: AppTypography.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm + AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search conversations',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(artisanConversationsProvider);
                await ref.read(artisanConversationsProvider.future);
              },
              color: AppColors.primary,
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => _ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(artisanConversationsProvider),
                ),
                data: (conversations) {
                  final filtered = _search.isEmpty
                      ? conversations
                      : conversations.where((c) {
                          final name = c.artisan?.name.toLowerCase() ?? '';
                          final service = c.service?.name.toLowerCase() ?? '';
                          final q = _search.toLowerCase();
                          return name.contains(q) || service.contains(q);
                        }).toList();

                  if (filtered.isEmpty) {
                    return const _EmptyView();
                  }

                  final sorted = [...filtered]
                    ..sort((a, b) => b.sortDate.compareTo(a.sortDate));

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) =>
                        _ConversationRow(conversation: sorted[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation});

  final ConversationSummary conversation;

  @override
  Widget build(BuildContext context) {
    final customer = conversation.artisan;
    final last = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0;
    final serviceName = conversation.service?.name;

    return Material(
      color: AppColors.cardLight,
      child: InkWell(
        onTap: () {
          final customerName = customer?.name ?? 'Customer';
          context.push(
            '/artisan-home/messages/chat/${conversation.id}'
            '?serviceRequestId=${conversation.serviceRequestId}'
            '&counterpartyName=${Uri.encodeComponent(customerName)}',
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 12,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderLight)),
          ),
          child: Row(
            children: [
              _Avatar(counterparty: customer),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer?.name ?? 'Customer',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeLabel(last?.createdAt),
                          style: AppTypography.caption.copyWith(
                            color: hasUnread
                                ? AppColors.secondary
                                : AppColors.textMuted,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (serviceName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        serviceName,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            last?.preview ?? 'No messages yet',
                            style: AppTypography.bodySmall.copyWith(
                              color: hasUnread
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadCount > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textInverse,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ] else if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeLabel(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(local.year, local.month, local.day);
    final diff = today.difference(that).inDays;
    if (diff <= 0) {
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff == 1) return 'Yesterday';
    return '${local.day}/${local.month}';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.counterparty});

  final ConversationArtisan? counterparty;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(counterparty);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderLight),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _initials(ConversationArtisan? c) {
    if (c == null) return '?';
    final f = c.firstName.isNotEmpty
        ? c.firstName[0]
        : (c.name.isNotEmpty ? c.name[0] : '?');
    final l = c.lastName.isNotEmpty ? c.lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

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
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No messages yet',
              style: AppTypography.h3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Conversations with customers will appear here once you '
              'have an active job.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
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
        ),
      ),
    );
  }
}
