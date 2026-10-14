import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/models/request_understanding.dart';
import '../../providers/ai_providers.dart';

/// Optional "Improve with AI" affordance for the create-request wizard.
///
/// Rules (per Customer spec §9 and §36):
///  - AI is optional; the manual flow never depends on it.
///  - AI never silently mutates the request; the user accepts/edits/dismisses.
///  - AI failure or low confidence renders a non-blocking inline message.
class AiUnderstandingCard extends ConsumerWidget {
  const AiUnderstandingCard({
    super.key,
    required this.description,
    this.serviceId,
    this.onAccept,
  });

  final String description;
  final String? serviceId;

  /// Called when the user taps "Use this" — the caller decides how to
  /// apply the suggestion (typically updates the wizard draft).
  final void Function(RequestUnderstanding understanding)? onAccept;

  bool get _canAnalyze => description.trim().length >= 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(draftUnderstandingProvider);
    final notifier = ref.read(draftUnderstandingProvider.notifier);

    return Container(
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
                  l10n.aiUnderstandTitle,
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
            l10n.aiUnderstandDescription,
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
                onPressed: _canAnalyze
                    ? () => notifier.analyze(
                          description: description,
                          serviceId: serviceId,
                        )
                    : null,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: Text(l10n.aiUnderstandButton),
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
                    l10n.aiUnderstandLoading,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

          if (state.errorMessage != null)
            _InlineMessage(
              icon: Icons.info_outline,
              message: l10n.aiUnavailableMessage,
            ),

          if (state.hasResult && state.understanding!.available == false)
            _InlineMessage(
              icon: Icons.info_outline,
              message: state.understanding!.isLowConfidence
                  ? l10n.aiLowConfidenceMessage
                  : l10n.aiUnavailableMessage,
            ),

          if (state.hasResult && state.understanding!.available)
            _UnderstandingResult(
              understanding: state.understanding!,
              onAccept: onAccept,
              onDismiss: notifier.clear,
            ),
        ],
      ),
    );
  }
}

class _UnderstandingResult extends StatelessWidget {
  const _UnderstandingResult({
    required this.understanding,
    required this.onAccept,
    required this.onDismiss,
  });

  final RequestUnderstanding understanding;
  final void Function(RequestUnderstanding)? onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (understanding.problemType != null) ...[
          _Row(label: l10n.aiProblemTypeLabel, value: understanding.problemType!),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (understanding.urgency != null) ...[
          _Row(
            label: l10n.aiUrgencyLabel,
            value: understanding.urgency!.name,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (understanding.usefulContext.isNotEmpty) ...[
          _Bullets(
            label: l10n.aiUsefulContextLabel,
            items: understanding.usefulContext,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (understanding.missingInformation.isNotEmpty) ...[
          _Bullets(
            label: l10n.aiMissingInfoLabel,
            items: understanding.missingInformation,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.aiAdvisoryDisclaimer,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDismiss,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: const StadiumBorder(),
                ),
                child: Text(l10n.aiDismiss),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton(
                onPressed: onAccept != null
                    ? () => onAccept!(understanding)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.textInverse,
                  shape: const StadiumBorder(),
                ),
                child: Text(l10n.aiUseSuggestion),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.label, required this.items});
  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: AppTypography.bodySmall),
                Expanded(
                  child: Text(
                    item,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
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