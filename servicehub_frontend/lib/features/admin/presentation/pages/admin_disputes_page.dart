import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../data/repositories/admin_dispute_repository.dart';
import '../providers/admin_dispute_providers.dart';
import '../widgets/disputes/cancel_resolution_dialog.dart';
import '../widgets/disputes/confirm_execution_dialog.dart';
import '../widgets/disputes/dispute_queue_item.dart';
import '../widgets/disputes/evidence_tile.dart';
import '../widgets/disputes/notes_dialog.dart';
import '../widgets/disputes/resolve_dispute_dialog.dart';
import '../widgets/disputes/status_pill.dart';
import '../widgets/disputes/urgency_pill.dart';

class AdminDisputesPage extends ConsumerStatefulWidget {
  const AdminDisputesPage({super.key});

  @override
  ConsumerState<AdminDisputesPage> createState() => _AdminDisputesPageState();
}

class _AdminDisputesPageState extends ConsumerState<AdminDisputesPage> {
  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(disputesListProvider);
    final selectedId = ref.watch(selectedDisputeIdProvider);

    return Row(
      children: [
        _queuePanel(listAsync, selectedId),
        Expanded(
          child: selectedId == null ? _emptyDetail() : _detailPanel(selectedId),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------
  // QUEUE PANEL
  // -----------------------------------------------------------------

  Widget _queuePanel(
    AsyncValue<List<DisputeSummary>> listAsync,
    String? selectedId,
  ) {
    return Container(
      width: 400,
      decoration: const BoxDecoration(
        color: AppColors.cardLight,
        border: Border(right: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        children: [
          _queueHeader(),
          const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(disputesListProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text('No disputes match the current filter.'),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.borderLight,
                  ),
                  itemBuilder: (_, i) {
                    final d = list[i];
                    return DisputeQueueItem(
                      dispute: d,
                      selected: d.id == selectedId,
                      onTap: () {
                        ref.read(selectedDisputeIdProvider.notifier).state =
                            d.id;
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _queueHeader() {
    final currentFilter = ref.watch(disputeStatusFilterProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Disputes',
            style: AppTypography.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(null, 'All', currentFilter),
                const SizedBox(width: 6),
                _filterChip('opened', 'Opened', currentFilter),
                const SizedBox(width: 6),
                _filterChip('under_review', 'Under review', currentFilter),
                const SizedBox(width: 6),
                _filterChip('pending_execution', 'Pending exec', currentFilter),
                const SizedBox(width: 6),
                _filterChip('awaiting_information', 'Awaiting', currentFilter),
                const SizedBox(width: 6),
                _filterChip('resolved', 'Resolved', currentFilter),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String? value, String label, String? current) {
    final active = current == value;
    return Material(
      color: active ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        borderRadius: BorderRadius.circular(9999),
        onTap: () {
          ref.read(disputeStatusFilterProvider.notifier).state = value;
          ref.read(selectedDisputeIdProvider.notifier).state = null;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.borderLight,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: active ? Colors.white : AppColors.textMuted,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // DETAIL PANEL
  // -----------------------------------------------------------------

  Widget _emptyDetail() {
    return Container(
      color: AppColors.bgLight,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.gavel_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Select a dispute',
            style: AppTypography.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose a dispute from the queue on the left.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailPanel(String disputeId) {
    final detailAsync = ref.watch(disputeDetailProvider(disputeId));
    final action = ref.watch(disputeActionProvider);

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorView(
        message: err.toString(),
        onRetry: () => ref.invalidate(disputeDetailProvider(disputeId)),
      ),
      data: (response) => Container(
        color: AppColors.bgLight,
        child: Column(
          children: [
            _detailHeader(response, action.inFlight),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _summarySection(response),
                    const SizedBox(height: 24),
                    _evidenceSection(response),
                    const SizedBox(height: 24),
                    _financialsSection(response),
                    const SizedBox(height: 24),
                    _timelineSection(response),
                    if (response.dispute.resolution != null ||
                        response.dispute.pendingResolution != null) ...[
                      const SizedBox(height: 24),
                      _resolutionSection(response),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailHeader(DisputeDetailResponse response, bool busy) {
    final d = response.dispute;
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
      decoration: const BoxDecoration(
        color: AppColors.cardLight,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'DISPUTE #${d.shortId}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DisputeStatusPill(status: d.status),
              if (response.simulationNotice != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningTint,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.science_outlined,
                        size: 12,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SIMULATED',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                _relativeTime(d.createdAt),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            d.reason,
            style: AppTypography.h3.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _metaChip(
                'Reporter',
                '${d.reporterName ?? "—"} (${_titleCase(d.reporterRole)})',
              ),
              if (response.payment != null)
                _metaChip(
                  'Amount at stake',
                  _formatXaf((response.payment!.amount ?? 0).toInt()),
                ),
              if (d.urgency != null) UrgencyPill(urgency: d.urgency),
            ],
          ),
          const SizedBox(height: 16),
          _actionBar(response, busy),
        ],
      ),
    );
  }

  Widget _metaChip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: AppTypography.caption.copyWith(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _actionBar(DisputeDetailResponse response, bool busy) {
    final status = response.dispute.status;
    final actions = _actionsFor(status, response);

    return Row(mainAxisAlignment: MainAxisAlignment.end, children: actions);
  }

  List<Widget> _actionsFor(String status, DisputeDetailResponse response) {
    final d = response.dispute;
    final actions = <Widget>[];
    final hasPayment = response.payment != null;

    switch (status) {
      case 'opened':
        actions.add(
          _primaryButton(
            'Start review',
            Icons.visibility_outlined,
            AppColors.primary,
            () => _runNotes(
              d.id,
              title: 'Start review',
              confirmLabel: 'Start review',
              hintText:
                  'Explain why this dispute is entering review. Minimum 5 characters.',
              action: (repo, notes) => repo.startReview(d.id, notes),
            ),
          ),
        );
        break;
      case 'under_review':
        actions.add(
          _outlineButton(
            'Await information',
            () => _runNotes(
              d.id,
              title: 'Await information',
              confirmLabel: 'Await information',
              hintText:
                  'Explain what additional information is needed from the parties. Minimum 5 characters.',
              action: (repo, notes) => repo.awaitInformation(d.id, notes),
            ),
          ),
        );
        actions.add(const SizedBox(width: 8));
        actions.add(
          _outlineButton(
            'Investigate',
            () => _runNotes(
              d.id,
              title: 'Investigate',
              confirmLabel: 'Investigate',
              hintText:
                  'Explain the investigation approach. Minimum 5 characters.',
              action: (repo, notes) => repo.investigate(d.id, notes),
            ),
          ),
        );
        if (hasPayment) {
          actions.add(const SizedBox(width: 8));
          actions.add(
            _primaryButton(
              'Resolve',
              Icons.gavel_outlined,
              AppColors.primary,
              () => _runResolve(response),
            ),
          );
        }
        break;
      case 'awaiting_information':
        actions.add(
          _primaryButton(
            'Return to review',
            Icons.refresh,
            AppColors.primary,
            () => _runNotes(
              d.id,
              title: 'Return to review',
              confirmLabel: 'Return to review',
              hintText:
                  'Explain why this dispute is returning to review. Minimum 5 characters.',
              action: (repo, notes) => repo.startReview(d.id, notes),
            ),
          ),
        );
        break;
      case 'under_investigation':
        if (hasPayment) {
          actions.add(
            _primaryButton(
              'Resolve',
              Icons.gavel_outlined,
              AppColors.primary,
              () => _runResolve(response),
            ),
          );
        } else {
          actions.add(
            _primaryButton(
              'Return to review',
              Icons.refresh,
              AppColors.primary,
              () => _runNotes(
                d.id,
                title: 'Return to review',
                confirmLabel: 'Return to review',
                hintText:
                    'Explain why this dispute is returning to review. Minimum 5 characters.',
                action: (repo, notes) => repo.startReview(d.id, notes),
              ),
            ),
          );
        }
        break;
      case 'pending_execution':
        actions.add(
          _outlineButton(
            'Cancel resolution',
            () => _runCancelResolution(d.id),
            color: AppColors.error,
          ),
        );
        actions.add(const SizedBox(width: 8));
        actions.add(
          _primaryButton(
            'Confirm and execute',
            Icons.check,
            AppColors.success,
            () => _runConfirm(d.id, d.pendingResolution ?? const {}),
          ),
        );
        break;
      case 'reconciliation_required':
        actions.add(
          _primaryButton(
            'Reconcile',
            Icons.balance_outlined,
            AppColors.secondary,
            () => _runNotes(
              d.id,
              title: 'Reconcile dispute',
              confirmLabel: 'Complete reconciliation',
              hintText:
                  'Explain how the reconciliation was completed. Minimum 5 characters.',
              action: (repo, notes) => repo.reconcile(d.id, notes),
              confirmColor: AppColors.secondary,
            ),
          ),
        );
        break;
      case 'resolved':
      case 'closed':
        actions.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successTint,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              'Completed',
              style: AppTypography.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        );
        break;
      case 'resolved_with_manual_refund_pending':
        actions.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warningTint,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              'Awaiting manual refund',
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        );
        break;
    }

    return actions;
  }

  Widget _primaryButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        minimumSize: const Size(0, 40),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _outlineButton(
    String label,
    VoidCallback onTap, {
    Color color = AppColors.secondary,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      child: Text(label),
    );
  }

  // -----------------------------------------------------------------
  // ACTION HANDLERS
  // -----------------------------------------------------------------

  Future<void> _runNotes(
    String disputeId, {
    required String title,
    required String confirmLabel,
    required String hintText,
    required Future<void> Function(AdminDisputeRepository, String) action,
    Color? confirmColor,
  }) async {
    final notes = await showNotesDialog(
      context,
      title: title,
      confirmLabel: confirmLabel,
      hintText: hintText,
      confirmColor: confirmColor,
    );
    if (notes == null || !mounted) return;

    final ok = await ref
        .read(disputeActionProvider.notifier)
        .run(disputeId, (repo) => action(repo, notes));
    if (!mounted) return;
    _showResult(ok, 'Action completed.', 'Action failed.');
  }

  Future<void> _runResolve(DisputeDetailResponse response) async {
    final result = await showResolveDisputeDialog(
      context,
      dispute: response.dispute,
      payment: response.payment,
    );
    if (result == null || !mounted) return;

    final ok = await ref
        .read(disputeActionProvider.notifier)
        .run(
          response.dispute.id,
          (repo) => repo.resolve(
            id: response.dispute.id,
            decision: result.decision,
            customerRefundAmount: result.customerRefundAmount,
            artisanGrossRelease: result.artisanGrossRelease,
            reason: result.reason,
            resolutionReference: result.resolutionReference,
          ),
        );
    if (!mounted) return;
    _showResult(ok, 'Resolution initiated.', 'Could not initiate.');
  }

  Future<void> _runConfirm(
    String disputeId,
    Map<String, dynamic> pending,
  ) async {
    final ok = await showConfirmExecutionDialog(
      context,
      pendingResolution: pending,
    );
    if (ok != true || !mounted) return;

    final success = await ref
        .read(disputeActionProvider.notifier)
        .run(disputeId, (repo) => repo.confirmResolution(disputeId));
    if (!mounted) return;
    _showResult(success, 'Resolution executed.', 'Execution failed.');
  }

  Future<void> _runCancelResolution(String disputeId) async {
    final reason = await showCancelResolutionDialog(context);
    if (reason == null || !mounted) return;

    final ok = await ref
        .read(disputeActionProvider.notifier)
        .run(disputeId, (repo) => repo.cancelResolution(disputeId, reason));
    if (!mounted) return;
    _showResult(ok, 'Resolution cancelled.', 'Cancel failed.');
  }

  void _showResult(bool ok, String successMsg, String failMsg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? successMsg : failMsg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  // -----------------------------------------------------------------
  // SECTIONS
  // -----------------------------------------------------------------

  Widget _sectionCard({
    required String title,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
          Padding(padding: const EdgeInsets.all(24), child: child),
        ],
      ),
    );
  }

  Widget _summarySection(DisputeDetailResponse response) {
    final d = response.dispute;
    return _sectionCard(
      title: 'Summary',
      icon: Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Reason', d.reason),
          const SizedBox(height: 10),
          _kv('Urgency', d.urgency != null ? _titleCase(d.urgency!) : '—'),
          const SizedBox(height: 10),
          _kv(
            'Reporter',
            '${d.reporterName ?? "—"} (${_titleCase(d.reporterRole)})',
          ),
          const SizedBox(height: 10),
          _kv('Service', d.serviceName ?? '—'),
          const SizedBox(height: 10),
          _kv('Prior status', d.priorRequestStatus ?? '—'),
          const SizedBox(height: 16),
          Text(
            'Description',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            d.description.isEmpty ? '—' : d.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _evidenceSection(DisputeDetailResponse response) {
    final evidence = response.dispute.evidence;
    return _sectionCard(
      title: 'Evidence',
      icon: Icons.image_outlined,
      trailing: Text(
        '${evidence.length} file${evidence.length == 1 ? '' : 's'}',
        style: AppTypography.caption.copyWith(
          color: AppColors.textMuted,
          fontSize: 11,
        ),
      ),
      child: evidence.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No evidence submitted',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          : Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final e in evidence)
                  EvidenceTile(
                    evidence: e,
                    onTap: () => _viewEvidence(
                      response.dispute.id,
                      e['id']?.toString() ?? '',
                      e['name']?.toString() ?? 'Evidence',
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _financialsSection(DisputeDetailResponse response) {
    final p = response.payment;
    if (p == null) {
      return _sectionCard(
        title: 'Financials',
        icon: Icons.payments_outlined,
        child: Text(
          'No escrow payment is attached to this dispute. Financial resolutions are not available.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
        ),
      );
    }

    return _sectionCard(
      title: 'Financials',
      icon: Icons.payments_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Escrow amount', _formatXaf((p.amount ?? 0).toInt())),
          const SizedBox(height: 10),
          _kv('Currency', p.currency),
          const SizedBox(height: 10),
          _kv('Payment status', _titleCase(p.status)),
          const SizedBox(height: 10),
          _kv(
            'Commission rate',
            p.commissionRateSnapshot != null
                ? '${(p.commissionRateSnapshot! * 100).toStringAsFixed(1)}%'
                : '—',
          ),
          const SizedBox(height: 10),
          _kv(
            'Commission amount',
            p.commissionAmount != null
                ? _formatXaf(p.commissionAmount!.toInt())
                : '—',
          ),
          const SizedBox(height: 10),
          _kv(
            'Artisan gross',
            p.artisanGrossAmount != null
                ? _formatXaf(p.artisanGrossAmount!.toInt())
                : '—',
          ),
          const SizedBox(height: 10),
          _kv(
            'Artisan net',
            p.artisanNetAmount != null
                ? _formatXaf(p.artisanNetAmount!.toInt())
                : '—',
          ),
        ],
      ),
    );
  }

  Widget _timelineSection(DisputeDetailResponse response) {
    final history = response.dispute.statusHistory;
    return _sectionCard(
      title: 'Timeline',
      icon: Icons.history_outlined,
      child: history.isEmpty
          ? Text(
              'No transitions recorded.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < history.length; i++) ...[
                  _timelineRow(history[i]),
                  if (i < history.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  Widget _timelineRow(Map<String, dynamic> entry) {
    final status = entry['status']?.toString() ?? '—';
    final at = entry['occurred_at']?.toString();
    final notes = entry['notes']?.toString();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.cream,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.circle, size: 8, color: AppColors.secondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titleCase(status.replaceAll('_', ' ')),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  notes,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ],
              if (at != null) ...[
                const SizedBox(height: 2),
                Text(
                  _relativeTime(DateTime.tryParse(at)),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _resolutionSection(DisputeDetailResponse response) {
    final d = response.dispute;
    final resolution = d.resolution ?? d.pendingResolution;
    if (resolution == null) return const SizedBox.shrink();

    final isPending =
        d.pendingResolution != null && d.status == 'pending_execution';
    final decision = resolution['decision']?.toString() ?? '—';
    final refund = (resolution['customer_refund_amount'] as num?)?.toInt() ?? 0;
    final gross = (resolution['artisan_gross_release'] as num?)?.toInt() ?? 0;
    final commission = (resolution['commission_amount'] as num?)?.toInt() ?? 0;
    final net = (resolution['artisan_net_amount'] as num?)?.toInt() ?? 0;
    final reference = resolution['resolution_reference']?.toString() ?? '—';
    final status = resolution['status']?.toString() ?? '—';
    final reason = resolution['reason']?.toString() ?? '';

    return _sectionCard(
      title: isPending ? 'Pending resolution — 15 min window' : 'Resolution',
      icon: Icons.balance_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Decision', _decisionLabel(decision)),
          const SizedBox(height: 10),
          _kv('Refund to customer', _formatXaf(refund)),
          const SizedBox(height: 10),
          _kv('Release to artisan (gross)', _formatXaf(gross)),
          const SizedBox(height: 10),
          _kv('Artisan net (after commission)', _formatXaf(net)),
          const SizedBox(height: 10),
          _kv('Commission', _formatXaf(commission)),
          const SizedBox(height: 10),
          _kv('Status', _titleCase(status.replaceAll('_', ' '))),
          const SizedBox(height: 10),
          _kv('Resolution reference', reference),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            _kv('Reason', reason),
          ],
        ],
      ),
    );
  }

  String _decisionLabel(String key) {
    switch (key) {
      case 'refund_customer':
        return 'Refund customer';
      case 'release_artisan':
        return 'Release to artisan';
      case 'split_resolution':
        return 'Split resolution';
      case 'hold':
        return 'Hold for investigation';
      default:
        return key;
    }
  }

  // -----------------------------------------------------------------
  // HELPERS
  // -----------------------------------------------------------------

  Future<void> _viewEvidence(
    String disputeId,
    String evidenceId,
    String title,
  ) async {
    if (evidenceId.isEmpty) return;
    try {
      final result = await ref
          .read(adminDisputeRepositoryProvider)
          .downloadEvidence(disputeId: disputeId, evidenceId: evidenceId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.cardLight,
          insetPadding: const EdgeInsets.all(40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.h4.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderLight,
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: Image.memory(
                        Uint8List.fromList(result.bytes),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: Text(
                            'This file cannot be displayed as an image.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load evidence: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatXaf(int amount) =>
      '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} XAF';

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
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
