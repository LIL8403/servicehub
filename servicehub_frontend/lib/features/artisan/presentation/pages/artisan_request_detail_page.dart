import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servicehub_frontend/features/artisan/presentation/providers/artisan_conversations_providers.dart';
import 'package:servicehub_frontend/features/artisan/presentation/widgets/artisan_request_image_tile.dart';
import 'package:servicehub_frontend/features/artisan/presentation/widgets/artisan_request_map_preview.dart';
import 'package:servicehub_frontend/features/artisan/presentation/widgets/materials_proposal_card.dart';
import 'package:servicehub_frontend/features/artisan/presentation/widgets/quotation_summary_card.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../../customer/domain/enums/service_request_status.dart';
import '../../../customer/domain/models/service_request.dart';
import '../providers/artisan_request_providers.dart';
import '../widgets/artisan_status_badge.dart';
import '../widgets/decline_request_dialog.dart';

class ArtisanRequestDetailPage extends ConsumerStatefulWidget {
  const ArtisanRequestDetailPage({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<ArtisanRequestDetailPage> createState() =>
      _ArtisanRequestDetailPageState();
}

class _ArtisanRequestDetailPageState
    extends ConsumerState<ArtisanRequestDetailPage> {
  bool _submitting = false;
  String? _errorMessage;

  // ─────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────

  Future<void> _openConversation() async {
    final conversations = await ref
        .read(artisanConversationsRepositoryProvider)
        .list();

    final match = conversations.where(
      (c) => c.serviceRequestId == widget.requestId,
    );

    if (match.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No conversation is available yet.')),
      );
      return;
    }
    if (!mounted) return;

    final c = match.first;
    context.push(
      '/artisan-home/messages/chat/${c.id}'
      '?serviceRequestId=${c.serviceRequestId}'
      '&counterpartyName=${Uri.encodeComponent(c.artisan?.name ?? 'Customer')}',
    );
  }

  Future<void> _onAccept() async {
    final confirmed = await _confirm(
      title: 'Accept this request?',
      body:
          'The customer will be notified. You will be able to submit a '
          'quotation or propose an inspection next.',
      confirmLabel: 'Accept',
    );
    if (confirmed != true) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final ok = await ref
        .read(artisanActionProvider.notifier)
        .approve(widget.requestId);

    if (!mounted) return;

    if (ok) {
      ref.invalidate(artisanRequestDetailsProvider(widget.requestId));
      ref.invalidate(artisanRequestsProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request accepted.')));
    } else {
      setState(() {
        _submitting = false;
        _errorMessage =
            ref.read(artisanActionProvider).errorMessage ??
            'Could not accept the request.';
      });
    }
  }

  Future<void> _onStart() async {
    final confirmed = await _confirm(
      title: 'Start this job?',
      body:
          'You are confirming the job is booked and you are ready to '
          'begin work. The customer will be notified.',
      confirmLabel: 'Start job',
    );
    if (confirmed != true) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final ok = await ref
        .read(artisanActionProvider.notifier)
        .start(widget.requestId);

    if (!mounted) return;

    if (ok) {
      ref.invalidate(artisanRequestDetailsProvider(widget.requestId));
      ref.invalidate(artisanRequestsProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Job started.')));
    } else {
      setState(() {
        _submitting = false;
        _errorMessage =
            ref.read(artisanActionProvider).errorMessage ??
            'Could not start the job.';
      });
    }
  }

  void _onCompleteInspection() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Inspection completion form is coming next.'),
      ),
    );
  }

  void _onSubmitQuotation() {
    context.push('/artisan/requests/${widget.requestId}/quotation');
  }

  void _onProposeMaterials() {
    context.push('/artisan/requests/${widget.requestId}/materials');
  }

  void _onReportCompletion() {
    context.push('/artisan/requests/${widget.requestId}/completion');
  }

  Future<void> _onDecline() async {
    final reason = await showDeclineRequestDialog(context);
    if (reason == null) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final ok = await ref
        .read(artisanActionProvider.notifier)
        .decline(widget.requestId, reason: reason.isEmpty ? null : reason);

    if (!mounted) return;

    if (ok) {
      ref.invalidate(artisanRequestsProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request declined.')));
      context.pop();
    } else {
      setState(() {
        _submitting = false;
        _errorMessage =
            ref.read(artisanActionProvider).errorMessage ??
            'Could not decline the request.';
      });
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
        title: Text(
          title,
          style: AppTypography.h4.copyWith(color: AppColors.primary),
        ),
        content: Text(
          body,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmLabel,
              style: AppTypography.bodyMedium.copyWith(
                color: destructive ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(artisanRequestDetailsProvider(widget.requestId));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: async.when(
        loading: () => const _LoadingView(),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () =>
              ref.invalidate(artisanRequestDetailsProvider(widget.requestId)),
        ),
        data: (request) => _Body(
          request: request,
          submitting: _submitting,
          errorMessage: _errorMessage,
          onAccept: _onAccept,
          onDecline: _onDecline,
          onStart: _onStart,
          onReportCompletion: _onReportCompletion,
          onCompleteInspection: _onCompleteInspection,
          onSubmitQuotation: _onSubmitQuotation,
          onProposeMaterials: _onProposeMaterials,
          onMessage: _openConversation,
        ),
      ),
    );
  }
}

// ============================================================
// Body
// ============================================================

class _Body extends StatelessWidget {
  const _Body({
    required this.request,
    required this.submitting,
    required this.errorMessage,
    required this.onAccept,
    required this.onDecline,
    required this.onStart,
    required this.onReportCompletion,
    required this.onCompleteInspection,
    required this.onSubmitQuotation,
    required this.onProposeMaterials,
    required this.onMessage,
  });

  final ServiceRequest request;
  final bool submitting;
  final String? errorMessage;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onStart;
  final VoidCallback onReportCompletion;
  final VoidCallback onCompleteInspection;
  final VoidCallback onSubmitQuotation;
  final VoidCallback onProposeMaterials;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _AppBar(onBack: () => context.pop()),
          _Breadcrumb(request: request),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ContextCard(request: request),
                  const SizedBox(height: AppSpacing.md),
                  _DescriptionCard(request: request),
                  const SizedBox(height: AppSpacing.md),
                  _CustomerCard(request: request),
                  const SizedBox(height: AppSpacing.md),
                  _LocationCard(request: request),
                  const SizedBox(height: AppSpacing.md),
                  _ScheduleCard(request: request),
                  if (request.quotation != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    QuotationSummaryCard(quotation: request.quotation!),
                  ],
                  if (request.materials != null &&
                      request.materials!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    MaterialsProposalCard(proposal: request.materials!),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _TimelineCard(request: request),
                  const SizedBox(height: AppSpacing.md),
                  _InfoCallout(status: request.status),
                  if (errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ErrorBanner(message: errorMessage!),
                  ],
                ],
              ),
            ),
          ),
          _BottomActions(
            status: request.status,
            submitting: submitting,
            onAccept: onAccept,
            onDecline: onDecline,
            onStart: onStart,
            onReportCompletion: onReportCompletion,
            onCompleteInspection: onCompleteInspection,
            onSubmitQuotation: onSubmitQuotation,
            onProposeMaterials: onProposeMaterials,
            onMessage: onMessage,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Cards
// ============================================================

class _AppBar extends StatelessWidget {
  const _AppBar({required this.onBack});

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
          Text(
            'Request',
            style: AppTypography.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final service = request.service?.name ?? 'Service';
    final location = request.location?.label ?? 'Location not set';
    final shortRef = request.id.length <= 6
        ? request.id.toUpperCase()
        : request.id.substring(request.id.length - 6).toUpperCase();

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
              '$service · $location',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'Ref: $shortRef',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final urgency = request.urgency ?? 'Not specified';
    final received = _relativeTime(request.createdAt);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArtisanStatusBadge(
            status: request.status,
            size: ArtisanStatusBadgeSize.medium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _statBlock('RECEIVED', received)),
              Container(width: 1, height: 32, color: AppColors.borderLight),
              Expanded(child: _statBlock('URGENCY', _capitalize(urgency))),
              Container(width: 1, height: 32, color: AppColors.borderLight),
              Expanded(
                child: _statBlock(
                  'BUDGET',
                  request.quotation == null
                      ? 'On quote'
                      : '${_money(request.quotation!.grandTotal)} XAF',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBlock(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _relativeTime(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _money(double amount) {
    final rounded = amount.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) buf.write(',');
      buf.write(rounded[i]);
    }
    return buf.toString();
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JOB DETAILS',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            request.description.isEmpty
                ? 'No description provided.'
                : request.description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              height: 1.5,
            ),
          ),
          if (request.imageAttachments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'PHOTOS',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: request.imageAttachments.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return ArtisanRequestImageTile(
                    requestId: request.id,
                    image: request.imageAttachments[index],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final customer = request.customer;
    final displayName = customer != null && customer.name.isNotEmpty
        ? customer.name
        : 'Customer';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUSTOMER',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppTypography.h4.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Full address and phone are shared once you accept.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final label = request.location?.label ?? 'Location not set';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SERVICE LOCATION',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ArtisanRequestMapPreview(request: request),
          const SizedBox(height: AppSpacing.sm + 2),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
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

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final schedule = request.preferredSchedule;
    final label = schedule?.displayLabel ?? 'Not specified';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREFERRED SCHEDULE',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (schedule?.notes != null && schedule!.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              schedule.notes!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final events = request.statusHistory;
    if (events.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATUS',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          for (var i = 0; i < events.length; i++)
            _TimelineRow(event: events[i], isLast: i == events.length - 1),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.isLast});

  final StatusHistoryEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final accent = isLast ? AppColors.secondary : AppColors.primary;
    final dotBg = isLast ? AppColors.cream : AppColors.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: dotBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: AppColors.borderLight,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.status.label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: accent,
                      fontWeight: isLast ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  if (event.occurredAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _relativeTime(event.occurredAt!),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _InfoCallout extends StatelessWidget {
  const _InfoCallout({required this.status});

  final ServiceRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (title, body) = _copyFor(status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.45),
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _copyFor(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.pendingArtisanResponse:
        return (
          'WHAT HAPPENS NEXT?',
          'If you accept, you can message the customer, propose an '
              'inspection if needed, or submit a quotation directly.',
        );
      case ServiceRequestStatus.artisanApproved:
        return (
          'WHAT HAPPENS NEXT?',
          'Submit your labour quotation next. If the job requires parts, '
              'you will propose them after the customer accepts your quote.',
        );
      case ServiceRequestStatus.inspectionScheduled:
        return (
          'WHAT HAPPENS NEXT?',
          'Complete the site inspection and record your findings. You can '
              'submit a quotation once the inspection is done.',
        );
      case ServiceRequestStatus.inspectionCompleted:
        return (
          'WHAT HAPPENS NEXT?',
          'Submit your quotation based on the inspection findings.',
        );
      case ServiceRequestStatus.paymentPending:
        return (
          'WHAT HAPPENS NEXT?',
          'The customer has accepted your quotation. If the job requires '
              'materials, propose them now. The customer pays once materials '
              'are approved, then the job is booked.',
        );
      case ServiceRequestStatus.booked:
        return (
          'WHAT HAPPENS NEXT?',
          'Tap "Start job" when you arrive on site. The customer is '
              'notified and the timer starts.',
        );
      case ServiceRequestStatus.inProgress:
        return (
          'WHAT HAPPENS NEXT?',
          'When the work is complete, report it. The customer then has '
              '48 hours to inspect and confirm before the payment releases.',
        );
      case ServiceRequestStatus.awaitingConfirmation:
        return (
          'WHAT HAPPENS NEXT?',
          'Waiting for the customer to confirm. If they do not respond '
              'within 48 hours, the payment releases automatically.',
        );
      default:
        return (
          'WHAT HAPPENS NEXT?',
          'Follow the timeline above. Contact support if anything is '
              'unclear.',
        );
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.errorTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 20, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Bottom actions
// ============================================================

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.status,
    required this.submitting,
    required this.onAccept,
    required this.onDecline,
    required this.onStart,
    required this.onReportCompletion,
    required this.onCompleteInspection,
    required this.onSubmitQuotation,
    required this.onProposeMaterials,
    required this.onMessage,
  });

  final ServiceRequestStatus status;
  final bool submitting;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onStart;
  final VoidCallback onReportCompletion;
  final VoidCallback onCompleteInspection;
  final VoidCallback onSubmitQuotation;
  final VoidCallback onProposeMaterials;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ServiceRequestStatus.pendingArtisanResponse:
        return _acceptDeclineBar();
      case ServiceRequestStatus.artisanApproved:
        return _singleButtonBar(
          label: 'Submit quotation',
          icon: Icons.receipt_long_outlined,
          onTap: onSubmitQuotation,
        );
      case ServiceRequestStatus.inspectionScheduled:
        return _singleButtonBar(
          label: 'Complete inspection',
          icon: Icons.fact_check_outlined,
          onTap: onCompleteInspection,
        );
      case ServiceRequestStatus.inspectionCompleted:
        return _singleButtonBar(
          label: 'Submit quotation',
          icon: Icons.receipt_long_outlined,
          onTap: onSubmitQuotation,
        );
      case ServiceRequestStatus.paymentPending:
        return _paymentPendingBar();
      case ServiceRequestStatus.booked:
        return _startJobBar();
      case ServiceRequestStatus.inProgress:
        return _inProgressBar();
      default:
        return _readOnlyBar();
    }
  }

  Widget _container({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardLight,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: child,
    );
  }

  Widget _acceptDeclineBar() {
    return _container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitting ? null : onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                disabledBackgroundColor: AppColors.disabledBg,
                disabledForegroundColor: AppColors.disabledText,
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: AppColors.textInverse,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Accept request',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: submitting ? null : onDecline,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.5),
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.close, size: 18, color: AppColors.error),
                  const SizedBox(width: 6),
                  Text(
                    'Decline request',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _singleButtonBar({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _container(
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: submitting ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.textInverse,
            disabledBackgroundColor: AppColors.disabledBg,
            disabledForegroundColor: AppColors.disabledText,
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: AppColors.textInverse),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentPendingBar() {
    return _container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitting ? null : onProposeMaterials,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.textInverse,
                disabledBackgroundColor: AppColors.disabledBg,
                disabledForegroundColor: AppColors.disabledText,
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: AppColors.textInverse,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Propose materials',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _messageButton(),
        ],
      ),
    );
  }

  Widget _startJobBar() {
    return _container(
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: submitting ? null : onStart,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textInverse,
            disabledBackgroundColor: AppColors.disabledBg,
            disabledForegroundColor: AppColors.disabledText,
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                size: 22,
                color: AppColors.textInverse,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Start job',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inProgressBar() {
    return _container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitting ? null : onReportCompletion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.textInverse,
                disabledBackgroundColor: AppColors.disabledBg,
                disabledForegroundColor: AppColors.disabledText,
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: AppColors.textInverse,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Report completion',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _messageButton(),
        ],
      ),
    );
  }

  Widget _readOnlyBar() {
    return _container(child: _messageButton());
  }

  Widget _messageButton() {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: submitting ? null : onMessage,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Message customer',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Loading & error
// ============================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _AppBar(onBack: () => context.pop()),
          Expanded(
            child: Center(
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
            ),
          ),
        ],
      ),
    );
  }
}
