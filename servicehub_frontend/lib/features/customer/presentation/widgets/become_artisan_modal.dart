import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Result returned by the modal when the user confirms.
class BecomeArtisanResult {
  const BecomeArtisanResult({
    required this.professionalDescription,
    required this.experienceYears,
  });

  final String professionalDescription;
  final int experienceYears;
}

/// Opens the "Become an artisan" modal. Returns the collected values
/// on confirm, or null on cancel.
Future<BecomeArtisanResult?> showBecomeArtisanModal(
  BuildContext context,
) {
  return showModalBottomSheet<BecomeArtisanResult>(
    context: context,
    backgroundColor: AppColors.cardLight,
    isScrollControlled: true,
    useRootNavigator: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: const _BecomeArtisanSheet(),
    ),
  );
}

class _BecomeArtisanSheet extends ConsumerStatefulWidget {
  const _BecomeArtisanSheet();

  @override
  ConsumerState<_BecomeArtisanSheet> createState() =>
      _BecomeArtisanSheetState();
}

class _BecomeArtisanSheetState
    extends ConsumerState<_BecomeArtisanSheet> {
  final _bioController = TextEditingController();
  final _yearsController = TextEditingController();
  String? _bioError;
  String? _yearsError;
  bool _isSubmitting = false;
  int _bioLength = 0;

  @override
  void initState() {
    super.initState();
    _bioController.addListener(_onBioChanged);
  }

  @override
  void dispose() {
    _bioController.removeListener(_onBioChanged);
    _bioController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  void _onBioChanged() {
    if (_bioLength != _bioController.text.length) {
      setState(() {
        _bioLength = _bioController.text.length;
        if (_bioError != null) _bioError = null;
      });
    }
  }

  bool get _isValid {
    final bio = _bioController.text.trim();
    final years = int.tryParse(_yearsController.text.trim());
    return bio.length >= 10 && years != null && years >= 0 && years <= 60;
  }

  Future<void> _submit() async {
    final bio = _bioController.text.trim();
    final years = int.tryParse(_yearsController.text.trim());

    setState(() {
      _bioError = bio.length < 10
          ? 'Please describe your work (minimum 10 characters).'
          : null;
      _yearsError = (years == null || years < 0 || years > 60)
          ? 'Experience must be between 0 and 60 years.'
          : null;
    });

    if (_bioError != null || _yearsError != null) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(authStateProvider.notifier).becomeArtisan(
            professionalDescription: bio,
            experienceYears: years!,
          );

      if (!mounted) return;

      Navigator.pop(
        context,
        BecomeArtisanResult(
          professionalDescription: bio,
          experienceYears: years,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _bioError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
                    Icons.handyman_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Become an artisan',
                        style: AppTypography.h4.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tell us about your work to get started.',
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
            const SizedBox(height: AppSpacing.lg),
            _label('PROFESSIONAL DESCRIPTION'),
            const SizedBox(height: 6),
            TextField(
              controller: _bioController,
              maxLines: 4,
              minLines: 4,
              maxLength: 2000,
              enabled: !_isSubmitting,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontSize: 13,
                height: 1.5,
              ),
              decoration: _decoration(
                hint: 'e.g. I am a plumber with 10 years of experience.',
                errorText: _bioError,
              ),
            ),
            if (_bioError == null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$_bioLength / 2000',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _label('YEARS OF EXPERIENCE'),
            const SizedBox(height: 6),
            TextField(
              controller: _yearsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: !_isSubmitting,
              onChanged: (_) {
                if (_yearsError != null) {
                  setState(() => _yearsError = null);
                } else {
                  setState(() {});
                }
              },
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontSize: 14,
              ),
              decoration: _decoration(
                hint: 'e.g. 5',
                errorText: _yearsError,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(
                          color: AppColors.borderLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          (_isValid && !_isSubmitting) ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textInverse,
                        disabledBackgroundColor: AppColors.disabledBg,
                        disabledForegroundColor: AppColors.disabledText,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  AppColors.textInverse,
                                ),
                              ),
                            )
                          : Text(
                              'Become an artisan',
                              style: AppTypography.bodyMedium.copyWith(
                                color: _isValid
                                    ? AppColors.textInverse
                                    : AppColors.disabledText,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
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

  InputDecoration _decoration({
    required String hint,
    String? errorText,
  }) {
    return InputDecoration(
      counterText: '',
      isDense: true,
      contentPadding: const EdgeInsets.all(AppSpacing.md),
      hintText: hint,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textMuted,
        fontSize: 13,
      ),
      filled: true,
      fillColor: AppColors.cardLight,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: errorText != null
              ? AppColors.error
              : AppColors.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      errorText: errorText,
      errorStyle: AppTypography.caption.copyWith(
        color: AppColors.error,
        fontSize: 11,
      ),
    );
  }
}