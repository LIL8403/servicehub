import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:servicehub_frontend/features/artisan/domain/models/verification_status.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../providers/artisan_verification_providers.dart';
import '../widgets/verification/verification_step_indicator.dart';
import '../widgets/verification/verification_text_field.dart';
import '../widgets/verification/rejection_card.dart';

class ArtisanIdentityFormPage extends ConsumerStatefulWidget {
  const ArtisanIdentityFormPage({super.key});

  @override
  ConsumerState<ArtisanIdentityFormPage> createState() =>
      _ArtisanIdentityFormPageState();
}

class _ArtisanIdentityFormPageState
    extends ConsumerState<ArtisanIdentityFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _legalNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();

  String? _dobError;
  bool _hydrated = false;

  @override
  void dispose() {
    _legalNameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Pre-fill from the current verification snapshot once it loads.
  void _hydrateFrom(VerificationStatus status) {
    if (_hydrated) return;
    _hydrated = true;

    if (status.legalName != null) {
      _legalNameController.text = status.legalName!;
    }
    if (status.dateOfBirth != null && status.dateOfBirth!.isNotEmpty) {
      _dobController.text = _formatForDisplay(status.dateOfBirth!);
    }
    if (status.residentialAddress != null) {
      _addressController.text = status.residentialAddress!;
    }
  }

  /// Reads the current rejection reason from the verification snapshot
  /// if the application is in the rejected state. Returns null otherwise.
  String? get _rejectionReason {
    final snapshot = ref.read(artisanVerificationProvider).valueOrNull;
    if (snapshot == null) return null;
    final status = snapshot.status;
    if (!status.isRejected) return null;
    final reason = status.rejectionReason;
    if (reason == null || reason.isEmpty) return null;
    return reason;
  }

  String _formatForDisplay(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final d = parsed.day.toString().padLeft(2, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    return '$d / $m / ${parsed.year}';
  }

  /// Returns ISO yyyy-MM-dd or null if invalid.
  String? _parseDob(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 8) return null;
    final d = int.tryParse(cleaned.substring(0, 2));
    final m = int.tryParse(cleaned.substring(2, 4));
    final y = int.tryParse(cleaned.substring(4, 8));
    if (d == null || m == null || y == null) return null;
    if (d < 1 || d > 31 || m < 1 || m > 12) return null;

    final date = DateTime.tryParse(
      '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}',
    );
    if (date == null) return null;

    // Age check: must be 18 or older
    final now = DateTime.now();
    var age = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age--;
    }
    if (age < 18) return null;

    return '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  void _onDobChanged(String value) {
    // Auto-insert separators: 12 / 04 / 1988
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 8; i++) {
      if (i == 2 || i == 4) buffer.write(' / ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    if (formatted != value) {
      _dobController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    if (_dobError != null) {
      setState(() => _dobError = null);
    }
  }

  Future<void> _onSave() async {
    final nameValid = _legalNameController.text.trim().length >= 2;
    final addressValid = _addressController.text.trim().length >= 5;
    final isoDob = _parseDob(_dobController.text);

    setState(() {
      _dobError = isoDob == null ? 'You must be at least 18 years old.' : null;
    });

    if (!nameValid || !addressValid || isoDob == null) {
      _formKey.currentState?.validate();
      return;
    }

    final ok = await ref
        .read(verificationActionProvider.notifier)
        .saveIdentity(
          legalName: _legalNameController.text.trim(),
          dateOfBirth: isoDob,
          residentialAddress: _addressController.text.trim(),
        );

    if (!mounted) return;

    if (ok) {
      context.push('/artisan-home/profile/verification/identity/document');
    } else {
      final error = ref.read(verificationActionProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Could not save. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hydrate from current verification snapshot when it arrives.
    ref.listen(artisanVerificationProvider, (_, next) {
      next.whenData((snapshot) => _hydrateFrom(snapshot.status));
    });
    final initialSnapshot = ref.read(artisanVerificationProvider);
    initialSnapshot.whenData((snapshot) => _hydrateFrom(snapshot.status));

    final isSubmitting = ref.watch(verificationActionProvider).isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          const VerificationStepIndicator(activeStep: 0),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_rejectionReason != null) ...[
                      RejectionCard(reason: _rejectionReason!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _introCard(),
                    const SizedBox(height: AppSpacing.md),
                    VerificationTextField(
                      label: 'Legal name',
                      controller: _legalNameController,
                      hintText: 'e.g. Jean Pierre Mbarga',
                      helperText: 'Must match your CNI or passport exactly.',
                      leadingIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    VerificationTextField(
                      label: 'Date of birth',
                      controller: _dobController,
                      hintText: 'DD / MM / YYYY',
                      errorText: _dobError,
                      leadingIcon: Icons.calendar_today_outlined,
                      trailingIcon: Icons.calendar_month_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      enabled: !isSubmitting,
                      onChanged: _onDobChanged,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _addressField(isSubmitting),
                    const SizedBox(height: AppSpacing.md),
                    _infoCallout(),
                  ],
                ),
              ),
            ),
          ),
          _bottomActions(isSubmitting),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        onPressed: () => context.pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Text(
            'Identity',
            style: AppTypography.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: SvgPicture.asset(
              'assets/brand/logo_symbol.svg',
              width: 28,
              height: 28,
            ),
          ),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.borderLight),
      ),
    );
  }

  Widget _introCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_outline,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Text(
                  'Legal identity',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            'We need your legal name exactly as it appears on your '
            'identity document. This helps us verify you as a real, '
            'trusted artisan.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressField(bool isSubmitting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RESIDENTIAL ADDRESS',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _addressController,
          enabled: !isSubmitting,
          maxLines: 4,
          minLines: 4,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md + 30,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            hintText: 'e.g. Rue 1.234, Bastos, Yaoundé',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md - 4,
                right: AppSpacing.sm,
                bottom: 60,
              ),
              child: Icon(
                Icons.location_on_outlined,
                size: 20,
                color: _addressController.text.isEmpty
                    ? AppColors.textMuted
                    : AppColors.primary,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
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
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            'Where you currently live. We never share this with customers.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCallout() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 6),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondaryLight.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Your ID document and a verification selfie are captured '
              'in the next step. Have them ready.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomActions(bool isSubmitting) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + 4,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                disabledBackgroundColor: AppColors.disabledBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                  : Text(
                      'Save & continue',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textInverse,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextButton(
              onPressed: isSubmitting ? null : () => context.pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
