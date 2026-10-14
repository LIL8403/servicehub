import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servicehub_frontend/features/customer/domain/models/materials_proposal.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/models/service_request.dart';
import '../../providers/payment_providers.dart';
import '../../providers/request_tracking_providers.dart';
import 'info_callout_card.dart';
import 'request_glance_card.dart';
import 'tracking_app_bar.dart';
import 'tracking_timeline.dart';
import 'materials_approval_card.dart';

class PaymentPendingView extends ConsumerStatefulWidget {
  const PaymentPendingView({super.key, required this.request});

  final ServiceRequest request;

  @override
  ConsumerState<PaymentPendingView> createState() => _PaymentPendingViewState();
}

class _PaymentPendingViewState extends ConsumerState<PaymentPendingView> {
  late final TextEditingController _phoneController;
  String? _idempotencyKey;
  String? _selectedProvider;

  /// Controls the polling lifecycle. When non-null, the app is actively
  /// checking the payment status every few seconds.
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _idempotencyKey = ref
        .read(paymentActionProvider.notifier)
        .generateIdempotencyKey();
  }

  double _materialsApprovedTotal(MaterialsProposal? proposal) {
    if (proposal == null || !proposal.isApproved) return 0;
    return proposal.estimatedTotal;
  }

  @override
  void dispose() {
    _isPolling = false;
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onPay() async {
    final digits = _phoneController.text.trim();

    if (!_isValidLocalNumber(digits)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 9-digit MTN or Orange number.'),
        ),
      );
      return;
    }

    if (_selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a payment method.')),
      );
      return;
    }

    final phone = '237$digits';

    final result = await ref
        .read(paymentActionProvider.notifier)
        .initiate(
          requestId: widget.request.id,
          phone: phone,
          idempotencyKey: _idempotencyKey!,
          provider: _selectedProvider!,
        );

    if (result == null) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Approve the payment prompt on your phone. The screen will '
          'update automatically once confirmed.',
        ),
        duration: Duration(seconds: 6),
      ),
    );

    // Kick off the polling loop. It stops itself on the first terminal
    // status, or after ~2 minutes.
    _startReconcilePolling(result.id);
  }

  /// Polls the backend every 5 seconds until the payment reaches a
  /// terminal state, or up to 24 attempts (2 minutes). The backend in
  /// turn queries CamPay's transaction-status endpoint and updates the
  /// request to `booked` when the payment is confirmed.
  Future<void> _startReconcilePolling(String paymentId) async {
    if (_isPolling) return;
    _isPolling = true;

    const pollInterval = Duration(seconds: 5);
    const maxAttempts = 24;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(pollInterval);

      if (!mounted || !_isPolling) return;

      try {
        final updated = await ref
            .read(paymentRepositoryProvider)
            .reconcile(paymentId);

        final status = updated.status.toLowerCase();

        if (status == 'held' ||
            status == 'released' ||
            status == 'failed' ||
            status == 'cancelled') {
          _isPolling = false;

          // The backend has already transitioned the request if the
          // payment was confirmed. Force the tracking screen to
          // re-fetch so it renders the correct view.
          ref.invalidate(serviceRequestDetailsProvider(widget.request.id));

          if (!mounted) return;
          if (status == 'held' || status == 'released') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment confirmed. Booking your artisan.'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'The payment could not be completed. Please try again.',
                ),
              ),
            );
          }
          return;
        }
      } catch (_) {
        // Transient error — keep polling. If the backend stays
        // unreachable we'll time out below.
      }
    }

    _isPolling = false;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Payment confirmation is taking longer than expected. '
          'Pull to refresh in a moment.',
        ),
      ),
    );
  }

  bool _isValidLocalNumber(String input) {
    if (input.length != 9) return false;
    if (!RegExp(r'^[0-9]{9}$').hasMatch(input)) return false;
    return input.startsWith('6') || input.startsWith('2');
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(paymentActionProvider);
    final quotation = widget.request.quotation;
    final artisanName =
        widget.request.selectedArtisan?.firstName ?? 'the artisan';

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          TrackingAppBar(onBack: () => context.pop(), onHelp: () {}),
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
                  RequestGlanceCard(request: widget.request),
                  const SizedBox(height: AppSpacing.md),
                  if (quotation != null)
                    _AmountCard(
                      quotation: quotation,
                      materialsApprovedTotal: _materialsApprovedTotal(
                        widget.request.materials,
                      ),
                    )
                  else
                    const _MissingAmountCard(),
                  const SizedBox(height: AppSpacing.md),
                  // Materials approval — only when the artisan has
                  // proposed a list and the customer still needs to
                  // approve it. Hidden once approved (the total on
                  // the card above already includes it).
                  if (widget.request.materials?.isNotEmpty ?? false)
                    if (widget.request.materials!.isPendingApproval) ...[
                      MaterialsApprovalCard(
                        requestId: widget.request.id,
                        proposal: widget.request.materials!,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  if (_isPolling) ...[
                    const _PollingBanner(),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _PaymentMethodSelector(
                    selected: _selectedProvider,
                    onChanged: (v) => setState(() => _selectedProvider = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PhoneField(controller: _phoneController),
                  const SizedBox(height: AppSpacing.md),
                  if (action.errorMessage != null) ...[
                    _ErrorBanner(message: action.errorMessage!),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  TrackingTimeline(request: widget.request),
                  const SizedBox(height: AppSpacing.md),
                  InfoCalloutCard(
                    title: 'What happens next?',
                    body:
                        'You will receive a prompt on your phone to authorise '
                        'the payment. Funds are held in ServiceHUB escrow '
                        'until you confirm the job is finished. $artisanName '
                        'will be notified once payment is secured.',
                  ),
                ],
              ),
            ),
          ),
          _BottomActions(
            isSubmitting: action.isSubmitting || _isPolling,
            enabled: true,
            onPay: _onPay,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _PollingBanner extends StatelessWidget {
  const _PollingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.5),
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiting for confirmation',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Approve the prompt on your phone. This screen will '
                  'update automatically.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
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

class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.selected,
    required this.onChanged,
  });

  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment method',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MethodCard(
                shortLabel: 'MTN MoMo',
                accent: const Color(0xFFFFCC00),
                isSelected: selected == 'mtn',
                onTap: () => onChanged('mtn'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MethodCard(
                shortLabel: 'Orange Money',
                accent: const Color(0xFFFF7900),
                isSelected: selected == 'orange',
                onTap: () => onChanged('orange'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Choose the mobile money service that matches your number.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.shortLabel,
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  final String shortLabel;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.12)
              : AppColors.cardLight,
          borderRadius: AppRadii.borderLg,
          border: Border.all(
            color: isSelected ? accent : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    shortLabel[0],
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle, size: 20, color: accent),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              shortLabel,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Mobile Money',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile money number',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: AppRadii.borderLg,
            border: Border.all(color: AppColors.borderLight),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Text(
                '+237',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(width: 1, height: 24, color: AppColors.borderLight),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: '6XX XXX XXX',
                    hintStyle: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the 9 digits of your MTN or Orange number.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.quotation,
    required this.materialsApprovedTotal,
  });

  final Quotation quotation;
  final double materialsApprovedTotal;

  double get _grandTotal => quotation.grandTotal + materialsApprovedTotal;

  @override
  Widget build(BuildContext context) {
    final hasMaterials = materialsApprovedTotal > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.secondary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'SECURE PAYMENT',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Breakdown when materials are present.
          if (hasMaterials) ...[
            _lineItem('Service (labour)', quotation.grandTotal),
            const SizedBox(height: 6),
            _lineItem('Materials', materialsApprovedTotal),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(height: 1, color: AppColors.borderLight),
            ),
          ],

          Text(
            'Amount due',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _money(_grandTotal),
                style: AppTypography.h1.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'XAF',
                style: AppTypography.h4.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'The amount stays held securely by ServiceHUB and is '
                    'only released to the artisan once you confirm the '
                    'work is complete.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineItem(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${_money(amount)} XAF',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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

class _MissingAmountCard extends StatelessWidget {
  const _MissingAmountCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_empty,
            size: 20,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Final payment details are being prepared. Pull to refresh '
              'in a moment.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
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

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.isSubmitting,
    required this.enabled,
    required this.onPay,
  });

  final bool isSubmitting;
  final bool enabled;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
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
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (isSubmitting || !enabled) ? null : onPay,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.textInverse,
            disabledBackgroundColor: AppColors.disabledBg,
            disabledForegroundColor: AppColors.disabledText,
            shape: const StadiumBorder(),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textInverse,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock,
                      size: 20,
                      color: AppColors.textInverse,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Review & pay',
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
}
