import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../providers/dispute_providers.dart';
import '../providers/request_tracking_providers.dart';

class ReportIssuePage extends ConsumerStatefulWidget {
  const ReportIssuePage({
    super.key,
    required this.requestId,
    required this.serviceName,
    required this.locationLabel,
  });

  final String requestId;
  final String serviceName;
  final String locationLabel;

  @override
  ConsumerState<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends ConsumerState<ReportIssuePage> {
  static const _categories = [
    ('Work not completed', Icons.pending_actions),
    ('Poor quality of work', Icons.thumb_down_outlined),
    ('Damage caused', Icons.broken_image_outlined),
    ('Payment or refund issue', Icons.payments_outlined),
    ('Unprofessional behaviour', Icons.report_outlined),
    ('Other', Icons.more_horiz),
  ];

  String? _selectedReason;
  String _urgency = 'medium';
  bool _acknowledged = false;
  final TextEditingController _descriptionController =
      TextEditingController();
  final List<File> _evidenceFiles = [];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;
    if (!mounted) return;
    setState(() {
      for (final file in picked) {
        if (_evidenceFiles.length >= 5) break;
        _evidenceFiles.add(File(file.path));
      }
    });
  }

  Future<void> _submit() async {
    final reason = _selectedReason;
    if (reason == null) return;
    if (_descriptionController.text.trim().length < 10) return;
    if (!_acknowledged) return;

    final ok = await ref.read(disputeSubmitProvider.notifier).open(
          requestId: widget.requestId,
          reason: reason,
          description: _descriptionController.text,
          urgency: _urgency,
          evidenceFiles: List.from(_evidenceFiles),
        );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted. Our team will review it.')),
      );
      ref.invalidate(serviceRequestDetailsProvider(widget.requestId));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(disputeSubmitProvider);
    final descriptionLength = _descriptionController.text.trim().length;
    final canSubmit = _selectedReason != null &&
        descriptionLength >= 10 &&
        _acknowledged &&
        !state.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AppBar(onBack: () => context.pop()),
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
                    _RequestSummaryCard(
                      serviceName: widget.serviceName,
                      locationLabel: widget.locationLabel,
                      requestId: widget.requestId,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CategoryPicker(
                      categories: _categories,
                      selected: _selectedReason,
                      onChanged: (v) =>
                          setState(() => _selectedReason = v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DescriptionCard(
                      controller: _descriptionController,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _EvidenceCard(
                      files: _evidenceFiles,
                      onAdd: _pickEvidence,
                      onRemove: (i) =>
                          setState(() => _evidenceFiles.removeAt(i)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _UrgencyCard(
                      selected: _urgency,
                      onChanged: (v) => setState(() => _urgency = v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AcknowledgmentCard(
                      checked: _acknowledged,
                      onChanged: (v) =>
                          setState(() => _acknowledged = v),
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ErrorBanner(message: state.errorMessage!),
                    ],
                  ],
                ),
              ),
            ),
            _BottomBar(
              canSubmit: canSubmit,
              isSubmitting: state.isSubmitting,
              onSubmit: _submit,
              onCancel: () => context.pop(),
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
            'Report an issue',
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

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.5),
        borderRadius: AppRadii.borderLg,
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: AppColors.secondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "We're here to help",
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tell us what went wrong and our team will review the '
                  'situation. Funds remain protected in escrow while we '
                  'investigate.',
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
}

class _RequestSummaryCard extends StatelessWidget {
  const _RequestSummaryCard({
    required this.serviceName,
    required this.locationLabel,
    required this.requestId,
  });

  final String serviceName;
  final String locationLabel;
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final short = requestId.length <= 6
        ? requestId.toUpperCase()
        : requestId.substring(requestId.length - 6).toUpperCase();

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
            'ABOUT THIS REQUEST',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          _Row(icon: Icons.build_outlined, text: serviceName, bold: true),
          const SizedBox(height: AppSpacing.sm),
          _Row(
            icon: Icons.location_on_outlined,
            text: locationLabel,
          ),
          const SizedBox(height: AppSpacing.sm),
          _Row(icon: Icons.tag, text: 'Ref: $short'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.text,
    this.bold = false,
  });

  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: (bold
                    ? AppTypography.bodyLarge
                    : AppTypography.bodyMedium)
                .copyWith(
              color: bold ? AppColors.primary : AppColors.textMuted,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  final List<(String, IconData)> categories;
  final String? selected;
  final ValueChanged<String> onChanged;

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
            "WHAT'S THE ISSUE?",
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          for (var i = 0; i < categories.length; i++) ...[
            _CategoryRow(
              label: categories[i].$1,
              icon: categories[i].$2,
              isSelected: selected == categories[i].$1,
              onTap: () => onChanged(categories[i].$1),
            ),
            if (i < categories.length - 1)
              const Divider(height: 1, color: AppColors.borderLight),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: isSelected
            ? const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.secondary, width: 2),
                ),
              )
            : null,
        child: Padding(
          padding: EdgeInsets.only(left: isSelected ? AppSpacing.sm : 0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.secondary
                    : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color:
                        isSelected ? AppColors.primary : AppColors.primary,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.textMuted,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Center(
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

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
            'DESCRIBE THE ISSUE',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 5,
            maxLength: 2000,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  'Please describe what happened in as much detail as '
                  'possible. Include dates, times, and any specific facts '
                  'that will help our team understand the situation.',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              counterText: '',
              filled: true,
              fillColor: AppColors.bgLight,
              contentPadding: const EdgeInsets.all(AppSpacing.sm + 2),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.borderMd,
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.borderMd,
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.files,
    required this.onAdd,
    required this.onRemove,
  });

  final List<File> files;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

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
            'ADD EVIDENCE (OPTIONAL)',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Photos help us resolve disputes faster.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (files.length < 5)
                  GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      decoration: BoxDecoration(
                        borderRadius: AppRadii.borderMd,
                        border: Border.all(
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add,
                            color: AppColors.textMuted,
                          ),
                          Text(
                            'Add',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                for (var i = 0; i < files.length; i++)
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(
                          right: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: AppRadii.borderMd,
                          image: DecorationImage(
                            image: FileImage(files[i]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: AppSpacing.sm + 4,
                        child: GestureDetector(
                          onTap: () => onRemove(i),
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
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgencyCard extends StatelessWidget {
  const _UrgencyCard({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

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
            'HOW URGENT IS THIS?',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Row(
            children: [
              for (final option in ['low', 'medium', 'high']) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(option),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected == option
                            ? AppColors.primary
                            : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: selected == option
                              ? AppColors.primary
                              : AppColors.borderLight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        option[0].toUpperCase() + option.substring(1),
                        style: AppTypography.bodySmall.copyWith(
                          color: selected == option
                              ? AppColors.textInverse
                              : AppColors.primary,
                          fontWeight: selected == option
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (option != 'high')
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AcknowledgmentCard extends StatelessWidget {
  const _AcknowledgmentCard({
    required this.checked,
    required this.onChanged,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: GestureDetector(
        onTap: () => onChanged(!checked),
        behavior: HitTestBehavior.opaque,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: checked
                      ? AppColors.primary
                      : AppColors.textMuted,
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.textInverse,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Text(
                'I confirm the details above are accurate to the best of my '
                'knowledge. I understand that false reports may result in '
                'account restrictions.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
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
          const Icon(
            Icons.error_outline,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.canSubmit,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onCancel,
  });

  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (canSubmit && !isSubmitting) ? onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
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
                          Icons.report_outlined,
                          size: 20,
                          color: AppColors.textInverse,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Submit report',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textInverse,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: onCancel,
            child: Text(
              'Cancel',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}