import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// A sticky horizontal row of anchor links that jump to a section in
/// the detail panel.
class VerificationSectionAnchorNav extends StatelessWidget {
  const VerificationSectionAnchorNav({
    super.key,
    required this.activeKey,
    required this.onSelect,
  });

  final String activeKey;
  final void Function(String key) onSelect;

  static const _anchors = <({String key, String label})>[
    (key: 'identity', label: 'Identity'),
    (key: 'id-document', label: 'ID document'),
    (key: 'selfie', label: 'Selfie'),
    (key: 'professional', label: 'Professional'),
    (key: 'documents', label: 'Documents'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _anchors.length; i++) ...[
            _anchor(_anchors[i].key, _anchors[i].label),
            if (i < _anchors.length - 1) const SizedBox(width: 24),
          ],
        ],
      ),
    );
  }

  Widget _anchor(String key, String label) {
    final active = key == activeKey;
    return InkWell(
      onTap: () => onSelect(key),
      child: Container(
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.secondary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: active ? AppColors.secondary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}