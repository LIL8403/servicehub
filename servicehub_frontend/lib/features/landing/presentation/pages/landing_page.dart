import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../widgets/language_selector.dart';
import '../widgets/trust_block.dart';

class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.cardLight,
      body: SafeArea(
        child: Stack(
          children: [
            // Cream wash behind hero area
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 380,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha:0.20),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(40),
                  ),
                ),
              ),
            ),

            // Scrollable content
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TOP BAR — language selector
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                    child: const Align(
                      alignment: Alignment.centerRight,
                      child: LanguageSelector(),
                    ),
                  ),

                  // 2. HERO AREA
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.xl),

                        // Stacked logo
                        Column(
                          children: [
                            SvgPicture.asset(
                              'assets/brand/logo_symbol.svg',
                              width: 96,
                              height: 96,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            RichText(
                              text: TextSpan(
                                style: AppTypography.h2.copyWith(
                                  fontSize: 24,
                                  letterSpacing: -0.02,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Service',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                  TextSpan(
                                    text: 'HUB',
                                    style:
                                        TextStyle(color: AppColors.secondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Headline
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: Text(
                            l10n.landingHeadline,
                            textAlign: TextAlign.center,
                            style: AppTypography.h1.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xs),

                        // Tagline
                        Text(
                          l10n.landingTagline,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // 3. PRIMARY ACTIONS
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/service-categories'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textInverse,
                              shape: const StadiumBorder(),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.landingCtaPrimary,
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: AppColors.textInverse,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                const Icon(
                                  Icons.arrow_forward,
                                  size: 20,
                                  color: AppColors.textInverse,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md - AppSpacing.xs / 2),
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.go('/artisans'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              l10n.landingCtaSecondary,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 4. AUTH LINKS
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        _AuthLinkRow(
                          prefix: l10n.landingAuthPrefixLogin,
                          action: l10n.landingAuthActionLogin,
                          onTap: () => context.go('/login'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _AuthLinkRow(
                          prefix: l10n.landingAuthPrefixRegister,
                          action: l10n.landingAuthActionRegister,
                          onTap: () => context.go('/register'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),

                  // 5. DIVIDER
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Container(
                      height: 1,
                      color: AppColors.borderLight,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 6. TRUST BLOCK
                  const TrustBlock(),

                  const SizedBox(height: AppSpacing.xl),

                  // 7. SAMPLE ARTISAN LINK
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/artisans/sample'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.landingSampleCta,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs + 2),
                          const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthLinkRow extends StatelessWidget {
  const _AuthLinkRow({
    required this.prefix,
    required this.action,
    required this.onTap,
  });

  final String prefix;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prefix,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}