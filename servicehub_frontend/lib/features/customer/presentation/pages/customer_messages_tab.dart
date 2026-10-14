import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/conversation_summary.dart';
import '../providers/artisan_selection_providers.dart';
import '../providers/customer_conversations_providers.dart';
import '../widgets/customer_search_bar.dart';

class CustomerMessagesTab extends ConsumerStatefulWidget {
  const CustomerMessagesTab({super.key});

  @override
  ConsumerState<CustomerMessagesTab> createState() =>
      _CustomerMessagesTabState();
}

class _CustomerMessagesTabState extends ConsumerState<CustomerMessagesTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(customerConversationsProvider);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Start a conversation from a service request.',
                  ),
                ),
              );
            },
          ),
        ],
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
            child: CustomerSearchBar(
              hint: 'Search conversations',
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(customerConversationsProvider);
                await ref.read(customerConversationsProvider.future);
              },
              color: AppColors.primary,
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) => _ErrorView(
                  message: err.toString(),
                  onRetry: () =>
                      ref.invalidate(customerConversationsProvider),
                ),
                data: (conversations) {
                  final filtered = _search.isEmpty
                      ? conversations
                      : conversations.where((c) {
                          final name = c.artisan?.name.toLowerCase() ?? '';
                          final service =
                              c.service?.name.toLowerCase() ?? '';
                          return name.contains(_search.toLowerCase()) ||
                              service.contains(_search.toLowerCase());
                        }).toList();

                  if (filtered.isEmpty) {
                    return const _EmptyView();
                  }

                  return _GroupedList(conversations: filtered);
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

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.conversations});

  final List<ConversationSummary> conversations;

  @override
  Widget build(BuildContext context) {
    final sorted = [...conversations]
      ..sort((a, b) => b.sortDate.compareTo(a.sortDate));

    final groups = <String, List<ConversationSummary>>{};
    for (final c in sorted) {
      groups.putIfAbsent(_groupLabel(c.sortDate), () => []).add(c);
    }

    final children = <Widget>[];
    for (final entry in groups.entries) {
      children.add(_GroupHeader(label: entry.key));
      for (final c in entry.value) {
        children.add(_ConversationRow(conversation: c));
      }
      children.add(const SizedBox(height: AppSpacing.sm));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: children,
    );
  }

  String _groupLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(that).inDays;
    if (diff <= 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return 'EARLIER';
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _ConversationRow extends ConsumerWidget {
  const _ConversationRow({required this.conversation});

  final ConversationSummary conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artisan = conversation.artisan;
    final last = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0;

    return Material(
      color: AppColors.cardLight,
      child: InkWell(
        onTap: () {
          context.push(
            '/customer-home/messages/chat/${conversation.id}'
            '?serviceRequestId=${conversation.serviceRequestId}'
            '&artisanName=${Uri.encodeComponent(artisan?.name ?? 'Artisan')}',
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 12,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.borderLight),
            ),
          ),
          child: Row(
            children: [
              _Avatar(artisan: artisan),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            artisan?.name ?? 'Artisan',
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(that).inDays;
    if (diff <= 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  }
}

class _Avatar extends ConsumerWidget {
  const _Avatar({required this.artisan});

  final ConversationArtisan? artisan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = _initials(artisan);

    final placeholder = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.7),
        shape: BoxShape.circle,
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

    final userId = artisan?.id ?? '';
    if (!(artisan?.hasPhoto ?? false) || userId.isEmpty) {
      return placeholder;
    }

    final asyncBytes = ref.watch(artisanPhotoProvider(userId));
    return ClipOval(
      child: SizedBox(
        width: 48,
        height: 48,
        child: asyncBytes.when(
          loading: () => placeholder,
          error: (_, _) => placeholder,
          data: (bytes) {
            if (bytes == null || bytes.isEmpty) return placeholder;
            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            );
          },
        ),
      ),
    );
  }

  String _initials(ConversationArtisan? a) {
    if (a == null) return '?';
    final f = a.firstName.isNotEmpty
        ? a.firstName[0]
        : (a.name.isNotEmpty ? a.name[0] : '?');
    final l = a.lastName.isNotEmpty ? a.lastName[0] : '';
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
              'Conversations with artisans will appear here once you have '
              'an active request.',
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
            const Icon(
              Icons.error_outline,
              size: 56,
              color: AppColors.error,
            ),
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