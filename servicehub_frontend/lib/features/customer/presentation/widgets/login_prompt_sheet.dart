import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';

/// Shows a bottom sheet prompting the guest to log in or register.
///
/// Returns true if the user chose to log in or register (navigation
/// handled by the caller), false if they chose to continue browsing.
enum LoginPromptResult { login, register, continueBrowsing }

Future<LoginPromptResult> showLoginPromptSheet(BuildContext context) async {
  final result = await showModalBottomSheet<LoginPromptResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.primaryDark.withValues(alpha: 0.6),
    builder: (context) => const _LoginPromptSheet(),
  );

  return result ?? LoginPromptResult.continueBrowsing;
}

class _LoginPromptSheet extends StatelessWidget {
  const _LoginPromptSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Connection Nexus logo
            SvgPicture.asset(
              'assets/brand/logo_symbol.svg',
              width: 48,
              height: 48,
            ),

            const SizedBox(height: AppSpacing.sm),

            // Title
            Text(
              l10n.loginPromptTitle,
              textAlign: TextAlign.center,
              style: AppTypography.h2.copyWith(color: AppColors.primary),
            ),

            const SizedBox(height: AppSpacing.xs),

            // Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                l10n.loginPromptBody,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Log In
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(LoginPromptResult.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text(
                  l10n.loginPromptLogin,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),

            // Create an Account
            SizedBox(
              height: 52,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop(LoginPromptResult.register);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  l10n.loginPromptRegister,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Continue browsing
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(LoginPromptResult.continueBrowsing),
              child: Text(
                l10n.loginPromptContinueBrowsing,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
