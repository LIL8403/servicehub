import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../data/repositories/admin_dispute_repository.dart';
import '../catalog/modal_shell.dart';

class ResolveResult {
  const ResolveResult({
    required this.decision,
    required this.customerRefundAmount,
    required this.artisanGrossRelease,
    required this.reason,
    required this.resolutionReference,
  });

  final String decision;
  final int customerRefundAmount;
  final int artisanGrossRelease;
  final String reason;
  final String resolutionReference;
}

Future<ResolveResult?> showResolveDisputeDialog(
  BuildContext context, {
  required DisputeDetail dispute,
  required DisputePayment? payment,
  String? initialDecision,
}) {
  return showModalShell<ResolveResult>(
    context: context,
    title: 'Resolve dispute',
    width: 560,
    child: _ResolveForm(
      dispute: dispute,
      payment: payment,
      initialDecision: initialDecision,
    ),
  );
}

class _ResolveForm extends StatefulWidget {
  const _ResolveForm({
    required this.dispute,
    required this.payment,
    this.initialDecision,
  });

  final DisputeDetail dispute;
  final DisputePayment? payment;
  final String? initialDecision;

  @override
  State<_ResolveForm> createState() => _ResolveFormState();
}

class _ResolveFormState extends State<_ResolveForm> {
  final _reasonController = TextEditingController();
  final _splitController = TextEditingController();
  late String _decision;
  late String _reference;

  @override
  void initState() {
    super.initState();
    _decision = widget.initialDecision ?? 'refund_customer';
    _reference = _generateUuid();
    // Default split to half for split_resolution.
    final held = _heldAmount;
    _splitController.text = (held ~/ 2).toString();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _splitController.dispose();
    super.dispose();
  }

  int get _heldAmount {
    final amt = widget.payment?.amount ?? 0;
    return amt is int ? amt : amt.toInt();
  }

  int get _commissionRate =>
      ((widget.payment?.commissionRateSnapshot ?? 0) * 100).round();

  ({int customerRefund, int artisanGross, int commission, int artisanNet})
      get _amounts {
    final held = _heldAmount;
    switch (_decision) {
      case 'refund_customer':
        return (
          customerRefund: held,
          artisanGross: 0,
          commission: 0,
          artisanNet: 0,
        );
      case 'release_artisan':
        final rate = (widget.payment?.commissionRateSnapshot ?? 0).toDouble();
        final commission = (held * rate).round();
        return (
          customerRefund: 0,
          artisanGross: held,
          commission: commission,
          artisanNet: held - commission,
        );
      case 'split_resolution':
        final parsed = int.tryParse(_splitController.text.trim()) ?? 0;
        final refund = parsed.clamp(0, held);
        final gross = held - refund;
        final rate = (widget.payment?.commissionRateSnapshot ?? 0).toDouble();
        final commission = (gross * rate).round();
        return (
          customerRefund: refund,
          artisanGross: gross,
          commission: commission,
          artisanNet: gross - commission,
        );
      case 'hold':
      default:
        return (
          customerRefund: 0,
          artisanGross: 0,
          commission: 0,
          artisanNet: 0,
        );
    }
  }

  bool get _hasAmounts => _decision != 'hold';

  bool get _valid {
    if (_reasonController.text.trim().length < 5) return false;
    if (_decision == 'split_resolution') {
      final parsed = int.tryParse(_splitController.text.trim());
      if (parsed == null || parsed < 0 || parsed > _heldAmount) {
        return false;
      }
    }
    return true;
  }

  void _submit() {
    if (!_valid) return;
    final amounts = _amounts;
    Navigator.pop(
      context,
      ResolveResult(
        decision: _decision,
        customerRefundAmount: amounts.customerRefund,
        artisanGrossRelease: amounts.artisanGross,
        reason: _reasonController.text.trim(),
        resolutionReference: _reference,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _userSummary(),
        const SizedBox(height: 20),
        _sectionLabel('DECISION'),
        const SizedBox(height: 8),
        _decisionRadio(
          value: 'refund_customer',
          title: 'Refund customer',
          helper:
              'Full refund of the escrow amount to the customer. SIMULATED — no real funds move.',
        ),
        const SizedBox(height: 10),
        _decisionRadio(
          value: 'release_artisan',
          title: 'Release to artisan',
          helper:
              'Full escrow release to the artisan, minus platform commission. This is a REAL payout.',
        ),
        const SizedBox(height: 10),
        _decisionRadio(
          value: 'split_resolution',
          title: 'Split resolution',
          helper:
              'Divide the escrow between both parties. SIMULATED refund + REAL payout.',
        ),
        const SizedBox(height: 10),
        _decisionRadio(
          value: 'hold',
          title: 'Hold for investigation',
          helper: 'No funds move. Puts the dispute into investigation.',
        ),
        if (_hasAmounts) ...[
          const SizedBox(height: 20),
          _sectionLabel('AMOUNTS'),
          const SizedBox(height: 8),
          _amountsPanel(),
          const SizedBox(height: 12),
          _simulationWarning(),
        ],
        const SizedBox(height: 20),
        _sectionLabel('REASON'),
        const SizedBox(height: 6),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          minLines: 3,
          maxLength: 2000,
          onChanged: (_) => setState(() {}),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.primary,
            fontSize: 13,
            height: 1.5,
          ),
          decoration: _fieldDecoration(
            "Explain the resolution to both parties. Minimum 5 characters.",
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_reasonController.text.length} / 2000',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionLabel('AUDIT REFERENCE'),
        const SizedBox(height: 6),
        _referenceField(),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 40),
              ),
              child: Text(
                'Cancel',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _valid ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.disabledBg,
                disabledForegroundColor: AppColors.disabledText,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                minimumSize: const Size(0, 40),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Initiate resolution',
                style: AppTypography.bodySmall.copyWith(
                  color: _valid ? Colors.white : AppColors.disabledText,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _userSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(widget.dispute.reporterName ?? '?'),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.dispute.reporterName ?? "Reporter"} · ${widget.dispute.serviceName ?? "Service"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.payment != null
                      ? 'Amount at stake: ${_formatXaf(_heldAmount)} · Request ${widget.dispute.serviceRequestId.length >= 6 ? widget.dispute.serviceRequestId.substring(widget.dispute.serviceRequestId.length - 6).toUpperCase() : ''}'
                      : 'No escrow attached · Request ${widget.dispute.serviceRequestId.length >= 6 ? widget.dispute.serviceRequestId.substring(widget.dispute.serviceRequestId.length - 6).toUpperCase() : ''}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decisionRadio({
    required String value,
    required String title,
    required String helper,
  }) {
    final selected = _decision == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _decision = value),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.cream.withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppColors.secondary
                  : AppColors.borderLight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.secondary : Colors.white,
                  border: Border.all(
                    color: selected
                        ? AppColors.secondary
                        : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      helper,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
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

  Widget _amountsPanel() {
    final a = _amounts;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _amountRow(
            'Customer refund',
            _decision == 'split_resolution'
                ? null
                : _formatXaf(a.customerRefund),
          ),
          const SizedBox(height: 8),
          _amountRow(
            'Artisan gross release',
            _formatXaf(a.artisanGross),
          ),
          const SizedBox(height: 8),
          _amountRow(
            'Commission ($_commissionRate% of gross)',
            _formatXaf(a.commission),
          ),
          const SizedBox(height: 8),
          _amountRow(
            'Artisan net',
            _formatXaf(a.artisanNet),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, String? value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        if (value == null)
          SizedBox(
            width: 120,
            child: TextField(
              controller: _splitController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                suffixText: 'XAF',
                suffixStyle: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          )
        else
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  Widget _simulationWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'SIMULATED — The refund portion does not move real funds. Only artisan releases are executed with the payment provider.',
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _referenceField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _reference,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          IconButton(
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(
              Icons.copy_outlined,
              color: AppColors.textMuted,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _reference));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reference copied'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      counterText: '',
      isDense: true,
      contentPadding: const EdgeInsets.all(12),
      hintText: hint,
      hintStyle: AppTypography.bodySmall.copyWith(
        color: AppColors.textMuted,
        fontSize: 13,
      ),
      filled: true,
      fillColor: AppColors.cardLight,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        fontSize: 10,
        letterSpacing: 0.8,
      ),
    );
  }

  String _formatXaf(int amount) =>
      '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} XAF';

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Generates a UUID v4 string. Pure Dart, no package needed.
  String _generateUuid() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}