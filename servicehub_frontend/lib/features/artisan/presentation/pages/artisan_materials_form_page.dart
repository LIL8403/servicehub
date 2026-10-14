import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servicehub_frontend/features/customer/domain/enums/service_request_status.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../providers/artisan_request_providers.dart';
import '../widgets/material_row_editor.dart';

/// The itemised materials proposal form. The artisan enters one row
/// per material, and the customer approves the resulting list before
/// the artisan can purchase anything on their behalf.
class ArtisanMaterialsFormPage extends ConsumerStatefulWidget {
  const ArtisanMaterialsFormPage({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<ArtisanMaterialsFormPage> createState() =>
      _ArtisanMaterialsFormPageState();
}

class _ArtisanMaterialsFormPageState
    extends ConsumerState<ArtisanMaterialsFormPage> {
  final List<_MaterialRow> _rows = [_MaterialRow()];
  String? _errorMessage;

  static const int _maxRows = 10;

  void _addRow() {
    if (_rows.length >= _maxRows) return;
    setState(() => _rows.add(_MaterialRow()));
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() => _rows.removeAt(index));
  }

  double get _estimatedTotal =>
      _rows.fold<double>(0, (sum, r) => sum + r.estimatedCost);

  bool get _hasValidRows => _rows.every(
    (r) =>
        r.name.trim().length >= 2 &&
        r.quantity > 0 &&
        r.unit.trim().isNotEmpty &&
        r.unitCost >= 0,
  );

  Future<void> _submit() async {
    if (!_hasValidRows) {
      setState(
        () => _errorMessage =
            'Please fill in every material row with a name, quantity, and '
            'unit cost.',
      );
      return;
    }

    setState(() => _errorMessage = null);

        // Guard: the backend only accepts material proposals when the
    // request is in payment_pending. Fail fast here with a friendly
    // message rather than round-tripping to the server.
    final request = ref.read(artisanRequestDetailsProvider(widget.requestId)).valueOrNull;
    if (request != null &&
        request.status != ServiceRequestStatus.paymentPending) {
      setState(() {
        _errorMessage =
            'Materials can only be proposed after the customer accepts '
            'your quotation.';
      });
      return;
    }

    final materials = _rows
        .map(
          (r) => <String, dynamic>{
            'name': r.name.trim(),
            'quantity': r.quantity,
            'unit': r.unit.trim(),
            'unit_cost': r.unitCost,
          },
        )
        .toList(growable: false);

    final ok = await ref
        .read(artisanActionProvider.notifier)
        .proposeMaterials(requestId: widget.requestId, materials: materials);

    if (!mounted) return;

    if (ok) {
      ref.invalidate(artisanRequestDetailsProvider(widget.requestId));
      ref.invalidate(artisanRequestsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Materials sent for customer approval.')),
      );
      context.pop();
    } else {
      setState(() {
        _errorMessage =
            ref.read(artisanActionProvider).errorMessage ??
            'Could not submit materials.';
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
                        const _IntroCard(),
                        const SizedBox(height: AppSpacing.md),
                        for (var i = 0; i < _rows.length; i++) ...[
                          MaterialRowEditor(
                            key: ValueKey(_rows[i].id),
                            index: i,
                            onChanged:
                                ({
                                  required name,
                                  required quantity,
                                  required unit,
                                  required unitCost,
                                }) {
                                  _rows[i].name = name;
                                  _rows[i].quantity = quantity;
                                  _rows[i].unit = unit;
                                  _rows[i].unitCost = unitCost;
                                  setState(() {});
                                },
                            onRemoved: () => _removeRow(i),
                          ),
                          if (i < _rows.length - 1)
                            const SizedBox(height: AppSpacing.sm + 2),
                        ],
                        if (_rows.length < _maxRows) ...[
                          const SizedBox(height: AppSpacing.sm + 2),
                          GestureDetector(
                            onTap: _addRow,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.cardLight,
                                borderRadius: AppRadii.borderMd,
                                border: Border.all(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add,
                                    size: 18,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Add material',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        _TotalCard(total: _estimatedTotal),
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

/// Internal mutable row model. Held by the page so that removing a row
/// from the middle doesn't shuffle the remaining rows' widgets.
class _MaterialRow {
  _MaterialRow()
    : id = UniqueKey().toString(),
      name = '',
      quantity = 1,
      unit = 'piece',
      unitCost = 0;

  final String id;
  String name;
  double quantity;
  String unit;
  double unitCost;

  double get estimatedCost => quantity * unitCost;
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
            'Propose materials',
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

class _IntroCard extends StatelessWidget {
  const _IntroCard();

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
                  'Materials are billed to the customer',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'List every part the customer must purchase for this job. '
                  'Prices are estimates. The customer approves the list '
                  'before you buy anything.',
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

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});

  final double total;

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
                      'ESTIMATED TOTAL',
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
                          'Materials',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_money(total)} XAF',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Added to the labour amount from your quotation '
                      'after the customer approves.',
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
                      'Send for approval',
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
