import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../data/repositories/admin_audit_log_repository.dart';
import '../providers/admin_audit_log_providers.dart';
import '../widgets/audit/audit_event_summary.dart';
import '../widgets/audit/audit_log_detail_dialog.dart';
import '../widgets/transactions/transaction_pagination_bar.dart';

class AdminAuditLogsPage extends ConsumerStatefulWidget {
  const AdminAuditLogsPage({super.key});

  @override
  ConsumerState<AdminAuditLogsPage> createState() =>
      _AdminAuditLogsPageState();
}

class _AdminAuditLogsPageState
    extends ConsumerState<AdminAuditLogsPage> {
  final _eventController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _eventController.addListener(_onEventChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _eventController.removeListener(_onEventChanged);
    _eventController.dispose();
    super.dispose();
  }

  void _onEventChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = _eventController.text.trim();
      final current = ref.read(adminAuditLogsFilterProvider);
      ref.read(adminAuditLogsFilterProvider.notifier).state =
          current.copyWith(
        eventType: query.isEmpty ? null : query,
        clearEventType: query.isEmpty,
        page: 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminAuditLogsPageProvider);
    final page = async.valueOrNull;
    final isLoadingFirstTime = async.isLoading && page == null;
    final hasError = async.hasError && page == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _pageHeader(),
          const SizedBox(height: 24),
          if (isLoadingFirstTime)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 120),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (hasError)
            _ErrorView(
              message: async.error.toString(),
              onRetry: () =>
                  ref.invalidate(adminAuditLogsPageProvider),
            )
          else if (page != null) ...[
            _filterBar(ref, page),
            const SizedBox(height: 24),
            _tableCard(context, ref, page),
          ],
        ],
      ),
    );
  }

  Widget _pageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audit Logs',
          style: AppTypography.h2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'A record of administrative actions and system events. '
          'Read-only.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _filterBar(WidgetRef ref, AdminAuditLogsResponse page) {
    return Row(
      children: [
        SizedBox(
          width: 280,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.filter_list,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _eventController,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Filter by event type...',
                      hintStyle: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Text(
          '${page.meta.total} event${page.meta.total == 1 ? '' : 's'}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _tableCard(
    BuildContext context,
    WidgetRef ref,
    AdminAuditLogsResponse page,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: page.logs.isEmpty
          ? _emptyState()
          : Column(
              children: [
                _headerRow(),
                for (var i = 0; i < page.logs.length; i++) ...[
                  _dataRow(context, page.logs[i]),
                  if (i < page.logs.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.borderLight,
                    ),
                ],
                TransactionPaginationBar(
                  total: page.meta.total,
                  from: page.meta.from,
                  to: page.meta.to,
                  currentPage: page.meta.currentPage,
                  lastPage: page.meta.lastPage,
                  itemLabel: 'events',
                  onPrevious: () {
                    final f = ref.read(adminAuditLogsFilterProvider);
                    if (f.page > 1) {
                      ref.read(adminAuditLogsFilterProvider.notifier).state =
                          f.copyWith(page: f.page - 1);
                    }
                  },
                  onNext: () {
                    final f = ref.read(adminAuditLogsFilterProvider);
                    if (f.page < page.meta.lastPage) {
                      ref.read(adminAuditLogsFilterProvider.notifier).state =
                          f.copyWith(page: f.page + 1);
                    }
                  },
                ),
              ],
            ),
    );
  }

  Widget _headerRow() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: _header('EVENT')),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _header('ACTOR')),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _header('SUBJECT')),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _header('DETAILS')),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: Align(
              alignment: Alignment.centerRight,
              child: _header('WHEN'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String label) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _dataRow(BuildContext context, AdminAuditLog log) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showAuditLogDetailDialog(context, log: log),
        hoverColor: AppColors.bgLight,
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      log.eventType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${log.shortId}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Text(
                  log.actorId ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      log.subjectType ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    if (log.subjectId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        log.subjectId!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AuditEventSummary(log: log),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 140,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _relativeTime(log.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'No events match your filters',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    return '${diff.inMinutes} min ago';
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
                foregroundColor: Colors.white,
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