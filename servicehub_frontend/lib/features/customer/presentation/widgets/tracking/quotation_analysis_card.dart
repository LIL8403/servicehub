import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../providers/ai_providers.dart';

/// Optional "Analyze Quotation" affordance shown next to a received quote.
///
/// Rules (per Customer spec §19 and §36):
///  - Advisory only; never accepts, rejects, or mutates a quotation.
///  - Never uses the word "fraudulent"; uses "unusual" / "flagged".
///  - Failure renders a non-blocking inline message; Accept/Reject remain.
class QuotationAnalysisCard extends ConsumerWidget {
  const QuotationAnalysisCard({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(quotationAnalysisProvider);
    final notifier = ref.read(quotationAnalysisProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.35),
        borderRadius: AppRadii.borderLg,
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 20,
                color: AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.aiQuotationTitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.aiQuotationDescription,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (!state.hasResult && !state.isLoading)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => notifier.analyze(requestId),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: Text(l10n.aiQuotationAnalyzeButton),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: BorderSide(
                    color: AppColors.secondary.withValues(alpha: 0.5),
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
            ),

          if (state.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.aiQuotationLoading,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

          if (state.errorMessage != null)
            _InlineMessage(message: l10n.aiUnavailableMessage),

          if (state.hasResult && state.analysis!.available == false)
            _InlineMessage(
              message: state.analysis!.reason == 'no_quotation'
                  ? l10n.aiQuotationNoQuote
                  : l10n.aiUnavailableMessage,
            ),

          if (state.hasResult && state.analysis!.available)
            _AnalysisResult(
              isFlagged: state.analysis!.isFlagged,
              explanation: state.analysis!.explanation ?? '',
              confidence: state.analysis!.confidenceScore,
              onDismiss: notifier.clear,
            ),
        ],
      ),
    );
  }
}

class _AnalysisResult extends StatelessWidget {
  const _AnalysisResult({
    required this.isFlagged,
    required this.explanation,
    required this.confidence,
    required this.onDismiss,
  });

  final bool isFlagged;
  final String explanation;
  final int confidence;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final color = isFlagged ? AppColors.warning : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isFlagged ? Icons.info_outline : Icons.check_circle_outline,
              size: 18,
              color: color,
            ),
            const SizedBox(width: AppSpacing.sm - 2),
            Expanded(
              child: Text(
                isFlagged
                    ? l10n.aiQuotationFlagged
                    : l10n.aiQuotationLooksTypical,
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (explanation.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            explanation,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.aiQuotationConfidence(confidence),
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.aiAdvisoryDisclaimer,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onDismiss,
            child: Text(l10n.aiDismiss),
          ),
        ),
      ],
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm - 2),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}