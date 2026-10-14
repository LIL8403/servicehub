import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../providers/artisan_verification_providers.dart';
import '../widgets/verification/verification_step_indicator.dart';
import '../widgets/verification/verification_text_field.dart';
import '../widgets/verification/verification_photo_slot.dart';

class ArtisanIdDocumentPage extends ConsumerStatefulWidget {
  const ArtisanIdDocumentPage({super.key});

  @override
  ConsumerState<ArtisanIdDocumentPage> createState() =>
      _ArtisanIdDocumentPageState();
}

class _ArtisanIdDocumentPageState
    extends ConsumerState<ArtisanIdDocumentPage> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();

  final _picker = ImagePicker();

  String _documentType = 'cni';
  File? _frontFile;
  File? _backFile;
  File? _selfiePreview;

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  bool get _requiresBack => _documentType == 'cni';
  bool get _hasExpiry => true;

  Future<void> _pickFront() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (picked == null) return;
    setState(() => _frontFile = File(picked.path));
  }

  Future<void> _pickBack() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (picked == null) return;
    setState(() => _backFile = File(picked.path));
  }

  Future<void> _pickSelfie() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;
    setState(() => _selfiePreview = File(picked.path));
  }

  Future<void> _onContinue() async {
    if (_frontFile == null) {
      _snack('Please capture the front of your ID document.');
      return;
    }
    if (_requiresBack && _backFile == null) {
      _snack('This document type requires a back image.');
      return;
    }
    if (_numberController.text.trim().length < 3) {
      _snack('Please enter the document number.');
      return;
    }
    if (_selfiePreview == null) {
      _snack('Please take a verification selfie.');
      return;
    }

    final action = ref.read(verificationActionProvider.notifier);

    // 1) Upload the ID document
    final docOk = await action.uploadIdentityDocument(
      documentType: _documentType,
      documentNumber: _numberController.text.trim(),
      expiresAt: _expiryController.text.trim().isEmpty
          ? null
          : _expiryController.text.trim(),
      front: _frontFile!,
      back: _requiresBack ? _backFile : null,
    );
    if (!mounted) return;
    if (!docOk) {
      _snack(
        ref.read(verificationActionProvider).errorMessage ??
            'Could not upload ID document.',
      );
      return;
    }

    // 2) Upload the selfie
    final selfieOk = await action.uploadSelfie(_selfiePreview!);
    if (!mounted) return;
    if (!selfieOk) {
      _snack(
        ref.read(verificationActionProvider).errorMessage ??
            'Could not upload selfie.',
      );
      return;
    }

    // 3) Both succeeded — return to hub, which auto-refreshes.
    _snack('Identity saved successfully.', success: true);
    context.go('/artisan-home/profile/verification');
  }

  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        ref.watch(verificationActionProvider).isSubmitting;

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
                    _introCard(),
                    const SizedBox(height: AppSpacing.md),
                    _documentTypePicker(),
                    const SizedBox(height: AppSpacing.md),
                    VerificationTextField(
                      label: 'Document number',
                      controller: _numberController,
                      hintText: 'e.g. 1234567890',
                      leadingIcon: Icons.badge_outlined,
                      enabled: !isSubmitting,
                    ),
                    if (_hasExpiry) ...[
                      const SizedBox(height: AppSpacing.md),
                      VerificationTextField(
                        label: 'Expiry date (optional)',
                        controller: _expiryController,
                        hintText: 'YYYY-MM-DD',
                        leadingIcon: Icons.event_outlined,
                        enabled: !isSubmitting,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    VerificationPhotoSlot(
                      label: 'Front of document',
                      file: _frontFile,
                      onPick: isSubmitting ? () {} : _pickFront,
                      onClear: isSubmitting
                          ? null
                          : () => setState(() => _frontFile = null),
                      isRequired: true,
                      hintText: 'Clearly show the photo, name, and number.',
                    ),
                    if (_requiresBack) ...[
                      const SizedBox(height: AppSpacing.md),
                      VerificationPhotoSlot(
                        label: 'Back of document',
                        file: _backFile,
                        onPick: isSubmitting ? () {} : _pickBack,
                        onClear: isSubmitting
                            ? null
                            : () => setState(() => _backFile = null),
                        isRequired: true,
                        hintText: 'Clearly show the back of your CNI.',
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    VerificationPhotoSlot(
                      label: 'Verification selfie',
                      file: _selfiePreview,
                      onPick: isSubmitting ? () {} : _pickSelfie,
                      onClear: isSubmitting
                          ? null
                          : () => setState(() => _selfiePreview = null),
                      isRequired: true,
                      hintText:
                          'Face the camera in good light. Remove hats or glasses.',
                      aspectRatio: 1.0,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _securityCallout(),
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
            'ID document',
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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              Icons.badge_outlined,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identity document',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Capture a clear photo of your CNI or passport, and a '
                  'selfie to confirm it is really you.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentTypePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DOCUMENT TYPE',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _typeChip(
                label: 'National ID (CNI)',
                selected: _documentType == 'cni',
                onTap: () => setState(() => _documentType = 'cni'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _typeChip(
                label: 'Passport',
                selected: _documentType == 'passport',
                onTap: () => setState(() => _documentType = 'passport'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _typeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.primary : AppColors.cardLight,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderLight,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: selected ? AppColors.textInverse : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _securityCallout() {
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
          const Icon(Icons.lock_outline, size: 20, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Your documents are stored securely and only seen by our '
              'verification team. They are never shared with customers.',
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
              onPressed: isSubmitting ? null : _onContinue,
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
                      'Save & finish identity',
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
                'Back',
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