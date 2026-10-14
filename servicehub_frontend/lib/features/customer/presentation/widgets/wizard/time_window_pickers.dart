import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';

class TimeWindowPickers extends StatelessWidget {
  const TimeWindowPickers({
    super.key,
    required this.earliest,
    required this.latest,
    required this.onEarliestChanged,
    required this.onLatestChanged,
  });

  final String? earliest;
  final String? latest;
  final ValueChanged<String> onEarliestChanged;
  final ValueChanged<String> onLatestChanged;

  static const List<String> _timeOptions = [
    '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
    '18:00', '19:00', '20:00',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.createRequestStep3TimeWindowLabel,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _TimeField(
                label: l10n.createRequestStep3EarliestLabel,
                value: earliest,
                hint: '09:00',
                options: _timeOptions,
                onChanged: onEarliestChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            Expanded(
              child: _TimeField(
                label: l10n.createRequestStep3LatestLabel,
                value: latest,
                hint: '12:00',
                options: _timeOptions,
                onChanged: onLatestChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String hint;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => _TimePickerSheet(
                options: options,
                initialValue: value,
              ),
            );
            if (selected != null) {
              onChanged(selected);
            }
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md - 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: AppRadii.borderLg,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: AppTypography.bodyMedium.copyWith(
                      color: value != null
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimePickerSheet extends StatelessWidget {
  const _TimePickerSheet({
    required this.options,
    required this.initialValue,
  });

  final List<String> options;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.xl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 280,
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option == initialValue;

                  return ListTile(
                    onTap: () => Navigator.of(context).pop(option),
                    title: Text(
                      option,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.primary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check,
                            color: AppColors.secondary,
                            size: 20,
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}