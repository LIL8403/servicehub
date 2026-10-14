import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// Renders a metadata map as an ordered key-value list with proper
/// formatting for percentages, nested objects, and long strings.
class AuditMetadataTable extends StatelessWidget {
  const AuditMetadataTable({super.key, required this.metadata});

  final Map<String, dynamic> metadata;

  @override
  Widget build(BuildContext context) {
    if (metadata.isEmpty) {
      return Text(
        'No metadata',
        style: AppTypography.caption.copyWith(
          color: AppColors.textMuted,
          fontStyle: FontStyle.italic,
          fontSize: 12,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in metadata.entries) ...[
          _row(entry.key, entry.value),
          if (entry.key != metadata.keys.last) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _row(String key, dynamic value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            key.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _valueWidget(key, value)),
      ],
    );
  }

  Widget _valueWidget(String key, dynamic value) {
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in value.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${e.key}: ${e.value}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      );
    }
    if (value is List) {
      return Text(
        value.map((e) => e.toString()).join(', '),
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      );
    }
    if (value is num && key.toLowerCase().contains('rate')) {
      return Text(
        '${(value * 100).toStringAsFixed(2)}%',
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      );
    }
    return Text(
      value.toString(),
      style: AppTypography.caption.copyWith(
        color: AppColors.primary,
        fontSize: 12,
        fontFamily: 'monospace',
      ),
    );
  }
}