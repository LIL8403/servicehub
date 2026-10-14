import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// A monospace reference value with a copy icon button.
class CopyableReferenceField extends StatelessWidget {
  const CopyableReferenceField({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value ?? '—';
    final hasValue = value != null && value!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            if (hasValue)
              IconButton(
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(
                  Icons.copy_outlined,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}