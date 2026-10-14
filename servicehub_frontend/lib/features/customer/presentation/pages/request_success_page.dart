import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';

class RequestSuccessPage extends StatefulWidget {
  const RequestSuccessPage({
    super.key,
    required this.requestId,
    required this.aiAssistEnabled,
  });

  final String requestId;
  final bool aiAssistEnabled;

  @override
  State<RequestSuccessPage> createState() => _RequestSuccessPageState();
}

class _RequestSuccessPageState extends State<RequestSuccessPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.cardLight,
      body: SafeArea(
        child: Stack(
          children: [
            // -----------------------------------------------------------------
            // Close X (top-right)
            // Returns the customer to the home placeholder. Once the real
            // customer dashboard is built, this should still land there.
            // -----------------------------------------------------------------
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.md,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => context.go('/customer-home'),
              ),
            ),

            // Centered content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cream.withValues(alpha: 0.6),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Title
                    Text(
                      l10n.createRequestSuccessTitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.h1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Body
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Text(
                        widget.aiAssistEnabled
                            ? l10n.createRequestSuccessBodyAi
                            : l10n.createRequestSuccessBodyNoAi,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                          height: 1.6,
                        ),
                      ),
                    ),

                    if (widget.aiAssistEnabled) ...[
                      const SizedBox(height: AppSpacing.md),
                      // Analyzing indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md - 2,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cream.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              l10n.createRequestSuccessAnalyzing,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const _AnimatedDots(),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom actions
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // -----------------------------------------------------------------
                    // PRIMARY CTA
                    //
                    // Behavior depends on the AI toggle chosen on Step 1:
                    //
                    //   AI ON  → "See Recommended Artisans"
                    //             goes to the artisan selection list for this request
                    //
                    //   AI OFF → "View Request"
                    //             goes to the request tracking screen (placeholder)
                    //
                    // FIX: previously this button always showed a "coming soon"
                    // snackbar. Now it navigates to the correct destination
                    // based on the AI variant. Route paths must be registered in
                    // app_router.dart (/service-request/:id/artisans and
                    // /service-request/:id).
                    // -----------------------------------------------------------------
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        // FIX: Both AI ON and AI OFF customers go to artisan selection.
                        // The AI flag only affects how the list is ordered (AI-ranked
                        // vs. top-rated), not whether selection happens at all.
                        onPressed: () => context.go(
                          '/customer-home/request/${widget.requestId}/artisans',
                        ),
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
                              // Label differs by mode, destination is the same.
                              widget.aiAssistEnabled
                                  ? l10n.createRequestSuccessSeeArtisans
                                  : l10n.createRequestSuccessBrowseArtisans, // new label — see ARB note below
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

                    // -----------------------------------------------------------------
                    // SECONDARY CTA (AI ON only)
                    //
                    // When AI is enabled, the customer sees two choices:
                    //   1. "See Recommended Artisans" (primary, above)
                    //   2. "View Request" (secondary, here)
                    //
                    // FIX: previously this showed a "coming soon" snackbar.
                    // Now it navigates to the request tracking placeholder.
                    // -----------------------------------------------------------------
                    const SizedBox(height: AppSpacing.sm + 2),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            context.go(
                          '/customer-home/request/${widget.requestId}',
                        ),
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
                          l10n.createRequestSuccessViewRequest,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // -----------------------------------------------------------------
                    // TERTIARY ACTION
                    //
                    // Always returns the customer to the home placeholder.
                    // -----------------------------------------------------------------
                    TextButton(
                      onPressed: () => context.go('/customer-home'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                      ),
                      child: Text(
                        l10n.createRequestSuccessBackHome,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
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
}

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = (_controller.value - delay) % 1.0;
            final opacity = 0.3 + 0.7 * (1 - (2 * t - 1).abs());

            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 3 : 0),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
