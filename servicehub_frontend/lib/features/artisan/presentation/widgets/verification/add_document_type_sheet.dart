import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/models/verification_document_type.dart';

/// A bottom sheet that lets the artisan pick which type of supporting
/// document they're about to upload.
///
/// Returns the selected [VerificationDocumentType] via Navigator.pop,
/// or null if cancelled.
Future<VerificationDocumentType?> showAddDocumentTypeSheet(
  BuildContext context, {
  required List<VerificationDocumentType> types,
}) {
  return showModalBottomSheet<VerificationDocumentType>(
    context: context,
    backgroundColor: AppColors.cardLight,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
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
            const SizedBox(height: AppSpacing.md),
            Text(
              'What are you adding?',
              style: AppTypography.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick the type that best matches your document.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final type in types)
              _TypeRow(
                type: type,
                onTap: () => Navigator.pop(ctx, type),
              ),
          ],
        ),
      ),
    ),
  );
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.type, required this.onTap});

  final VerificationDocumentType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm + 4,
            horizontal: AppSpacing.sm,
          ),
          child: Row(
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
                  Icons.description_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (type.description != null &&
                        type.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        type.description!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}