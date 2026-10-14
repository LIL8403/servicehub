import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../providers/artisan_request_providers.dart';
import '../widgets/money_text_field.dart';

class ArtisanQuotationFormPage extends ConsumerStatefulWidget {
  const ArtisanQuotationFormPage({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<ArtisanQuotationFormPage> createState() =>
      _ArtisanQuotationFormPageState();
}

class _ArtisanQuotationFormPageState
    extends ConsumerState<ArtisanQuotationFormPage> {
  final TextEditingController _scopeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  double _laborAmount = 0;
  int _validityDays = 7;
  String? _errorMessage;

  @override
  void dispose() {
    _scopeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final scope = _scopeController.text.trim();

    if (_laborAmount <= 0) {
      setState(
        () => _errorMessage = 'Please enter a labour cost greater than zero.',
      );
      return;
    }
    if (scope.length < 10) {
      setState(
        () => _errorMessage =
            'Please describe the scope of work (at least 10 characters).',
      );
      return;
    }

    setState(() => _errorMessage = null);

    final validUntil = DateTime.now()
        .add(Duration(days: _validityDays))
        .toIso8601String();

    final ok = await ref
        .read(artisanActionProvider.notifier)
        .submitQuotation(
          requestId: widget.requestId,
          laborAmount: _laborAmount,
          scope: scope,
          validUntil: validUntil,
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;

    if (ok) {
      ref.invalidate(artisanRequestDetailsProvider(widget.requestId));
      ref.invalidate(artisanRequestsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation sent to the customer.')),
      );
      context.pop();
    } else {
      setState(() {
        _errorMessage =
            ref.read(artisanActionProvider).errorMessage ??
            'Could not submit the quotation.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(artisanActionProvider);
    final async = ref.watch(artisanRequestDetailsProvider(widget.requestId));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorView(
            message: err.toString(),
            onRetry: () =>
                ref.invalidate(artisanRequestDetailsProvider(widget.requestId)),
          ),
          data: (request) {
            final serviceName = request.service?.name ?? 'Service';
            final location = request.location?.label ?? 'Location not set';
            final shortRef = widget.requestId.length <= 6
                ? widget.requestId.toUpperCase()
                : widget.requestId
                      .substring(widget.requestId.length - 6)
                      .toUpperCase();

            return Column(
              children: [
                _AppBar(onBack: () => context.pop()),
                _ReferenceStrip(
                  serviceName: serviceName,
                  location: location,
                  shortRef: shortRef,
                ),
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
                        _LabourCard(
                          onChanged: (v) => setState(() => _laborAmount = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const _MaterialsInfoCard(),
                        const SizedBox(height: AppSpacing.md),
                        _ScopeCard(controller: _scopeController),
                        const SizedBox(height: AppSpacing.md),
                        _ValidityCard(
                          selected: _validityDays,
                          onChanged: (v) => setState(() => _validityDays = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _NotesCard(controller: _notesController),
                        const SizedBox(height: AppSpacing.md),
                        _TotalCard(laborAmount: _laborAmount),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _ErrorBanner(message: _errorMessage!),
                        ],
                      ],
                    ),
                  ),
                ),
                _BottomActions(
                  submitting: action.isSubmitting,
                  onSubmit: _submit,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// Sub-widgets
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
            'Submit quotation',
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

class _ReferenceStrip extends StatelessWidget {
  const _ReferenceStrip({
    required this.serviceName,
    required this.location,
    required this.shortRef,
  });

  final String serviceName;
  final String location;
  final String shortRef;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.cream.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.build_outlined,
            size: 14,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$serviceName · $location · Ref: $shortRef',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabourCard extends StatelessWidget {
  const _LabourCard({required this.onChanged});

  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      label: 'LABOUR',
      child: MoneyTextField(
        label: 'Labor amount',
        hint: '0',
        helperText: 'Include your time, travel, and expertise.',
        onChanged: onChanged,
      ),
    );
  }
}

class _MaterialsInfoCard extends StatelessWidget {
  const _MaterialsInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.4),
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Materials are quoted separately',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Use the separate "Materials" form to itemise parts the '
                  'customer must approve. The final payment is calculated as '
                  'labour + approved materials.',
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

class _ScopeCard extends StatelessWidget {
  const _ScopeCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      label: 'SCOPE OF WORK',
      child: TextField(
        controller: controller,
        maxLines: 4,
        maxLength: 5000,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.primary,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText:
              'Describe what you will do. Be specific about parts you will '
              'replace, tasks you will perform, and any assumptions. '
              'At least 10 characters.',
          hintStyle: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
          counterText: '',
          filled: true,
          fillColor: AppColors.cardLight,
          contentPadding: const EdgeInsets.all(AppSpacing.sm + 2),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderMd,
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderMd,
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      label: 'NOTES (OPTIONAL)',
      child: TextField(
        controller: controller,
        maxLines: 3,
        maxLength: 1000,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.primary,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText:
              'Any clarifications for the customer. Warranty terms, '
              'assumptions, or scheduling notes.',
          hintStyle: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
          counterText: '',
          filled: true,
          fillColor: AppColors.cardLight,
          contentPadding: const EdgeInsets.all(AppSpacing.sm + 2),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderMd,
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderMd,
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _ValidityCard extends StatelessWidget {
  const _ValidityCard({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      label: 'QUOTE VALIDITY',
      child: Row(
        children: [
          for (final days in [3, 7, 14]) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(days),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected == days
                        ? AppColors.primary
                        : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: selected == days
                          ? AppColors.primary
                          : AppColors.borderLight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$days days',
                    style: AppTypography.bodySmall.copyWith(
                      color: selected == days
                          ? AppColors.textInverse
                          : AppColors.primary,
                      fontWeight: selected == days
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            if (days != 14) const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.laborAmount});

  final double laborAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: AppColors.secondary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LABOUR TOTAL',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Text(
                          'Labor amount',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_money(laborAmount)} XAF',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Materials are added to the final payment once the '
                      'customer approves your itemised proposal.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.child});

  final String label;
  final Widget child;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          child,
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
  const _BottomActions({required this.submitting, required this.onSubmit});

  final bool submitting;
  final VoidCallback onSubmit;

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
          onPressed: submitting ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.textInverse,
            disabledBackgroundColor: AppColors.disabledBg,
            disabledForegroundColor: AppColors.disabledText,
            shape: const StadiumBorder(),
          ),
          child: submitting
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
                      Icons.send_outlined,
                      size: 20,
                      color: AppColors.textInverse,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Send quotation',
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
