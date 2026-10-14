import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/models/availability.dart';
import 'time_picker_sheet.dart';

/// A single day in the weekly schedule.
///
/// Shows a toggle, and when enabled, one or more shift rows. Each
/// shift has a start time, end time, and a remove button. A "Add
/// another window" link appears below when the day is enabled.
class DayScheduleRow extends StatelessWidget {
  const DayScheduleRow({
    super.key,
    required this.day,
    required this.label,
    required this.shifts,
    required this.onToggleDay,
    required this.onShiftChanged,
    required this.onShiftRemoved,
    required this.onShiftAdded,
  });

  final String day;
  final String label;
  final List<Shift> shifts;
  final ValueChanged<bool> onToggleDay;
  final void Function(int index, Shift shift) onShiftChanged;
  final ValueChanged<int> onShiftRemoved;
  final VoidCallback onShiftAdded;

  bool get _enabled => shifts.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: _enabled ? AppColors.primary : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch.adaptive(
                value: _enabled,
                onChanged: onToggleDay,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                inactiveThumbColor: AppColors.cardLight,
                inactiveTrackColor: AppColors.borderLight,
              ),
            ],
          ),
          if (_enabled) ...[
            const SizedBox(height: 4),
            for (var i = 0; i < shifts.length; i++) ...[
              _ShiftRow(
                shift: shifts[i],
                onChanged: (s) => onShiftChanged(i, s),
                onRemove: shifts.length > 1 ? () => onShiftRemoved(i) : null,
              ),
              if (i < shifts.length - 1) const SizedBox(height: 6),
            ],
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onShiftAdded,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    'Add another window',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShiftRow extends StatelessWidget {
  const _ShiftRow({
    required this.shift,
    required this.onChanged,
    this.onRemove,
  });

  final Shift shift;
  final ValueChanged<Shift> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TimeChip(
            label: shift.start,
            onTap: () async {
              final picked = await showShiftTimePicker(
                context,
                initial: shift.start,
                title: 'Shift starts at',
              );
              if (picked != null) onChanged(shift.copyWith(start: picked));
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '–',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TimeChip(
            label: shift.end,
            onTap: () async {
              final picked = await showShiftTimePicker(
                context,
                initial: shift.end,
                title: 'Shift ends at',
              );
              if (picked != null) onChanged(shift.copyWith(end: picked));
            },
          ),
        ),
        if (onRemove != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.errorTint,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.close, size: 12, color: AppColors.error),
            ),
          ),
        ] else
          const SizedBox(width: 28),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: AppRadii.borderMd,
          border: Border.all(color: AppColors.borderLight),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
