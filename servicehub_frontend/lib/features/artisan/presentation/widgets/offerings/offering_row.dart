import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/models/service_offering.dart';

/// A single row in the offerings list. Actions are exposed through
/// [onEdit], [onToggleActive] and [onRemove].
class OfferingRow extends StatelessWidget {
  const OfferingRow({
    super.key,
    required this.offering,
    required this.serviceName,
    required this.categoryName,
    required this.onEdit,
    required this.onToggleActive,
    required this.onRemove,
  });

  final ServiceOffering offering;
  final String serviceName;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final active = offering.isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? AppColors.success : AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: active ? AppColors.primary : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    decoration: active ? null : TextDecoration.lineThrough,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<_RowAction>(
            icon: const Icon(
              Icons.more_vert,
              size: 18,
              color: AppColors.textMuted,
            ),
            onSelected: (action) {
              switch (action) {
                case _RowAction.edit:
                  onEdit();
                case _RowAction.toggle:
                  onToggleActive();
                case _RowAction.remove:
                  onRemove();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: _RowAction.edit, child: Text('Edit')),
              PopupMenuItem(
                value: _RowAction.toggle,
                child: Text(active ? 'Pause' : 'Activate'),
              ),
              const PopupMenuItem(
                value: _RowAction.remove,
                child: Text('Remove', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitle() {
    final parts = <String>[];
    if (offering.startingPrice != null && offering.startingPrice! > 0) {
      parts.add('From ${_money(offering.startingPrice!)} XAF');
    }
    if (!offering.isActive) parts.add('Paused');
    if (parts.isEmpty) return categoryName;
    return parts.join(' · ');
  }

  static String _money(double amount) {
    final s = amount.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

enum _RowAction { edit, toggle, remove }
