import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';

class DatePickerRow extends StatelessWidget {
  const DatePickerRow({
    super.key,
    required this.selectedDate,
    required this.onSelected,
    this.dayCount = 14,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelected;
  final int dayCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final dates = List<DateTime>.generate(
      dayCount,
      (i) => startOfToday.add(Duration(days: i)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: label + month
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.createRequestStep3SelectDate,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _monthLabel(l10n, dates.first),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Horizontal scrollable pill row
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected =
                  selectedDate != null &&
                  selectedDate!.year == date.year &&
                  selectedDate!.month == date.month &&
                  selectedDate!.day == date.day;

              return _DatePill(
                date: date,
                isSelected: isSelected,
                onTap: () => onSelected(date),
                locale: l10n.localeName,
              );
            },
          ),
        ),

        // Confirmation line
        if (selectedDate != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.createRequestStep3SelectedDate(
              _formattedSelected(l10n, selectedDate!),
            ),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  String _monthLabel(AppLocalizations l10n, DateTime date) {
    return DateFormat.yMMMM(l10n.localeName).format(date);
  }

  String _formattedSelected(AppLocalizations l10n, DateTime date) {
    return DateFormat.yMMMMEEEEd(l10n.localeName).format(date);
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.date,
    required this.isSelected,
    required this.onTap,
    required this.locale,
  });

  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final dayNumber = date.day.toString();
    final dayInitial = DateFormat.E(locale).format(date).substring(0, 1);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardLight,
          borderRadius: AppRadii.borderLg,
          border: isSelected
              ? null
              : Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Text(
                dayInitial,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textInverse.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 1),
            ],
            Text(
              dayNumber,
              style: AppTypography.bodyLarge.copyWith(
                color: isSelected ? AppColors.textInverse : AppColors.primary,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
