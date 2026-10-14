import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';

/// Opens a friendly time picker for a shift boundary.
///
/// Returns an `HH:mm` string, or null if the user cancels.
Future<String?> showShiftTimePicker(
  BuildContext context, {
  required String initial,
  required String title,
}) {
  // Parse "HH:mm" → TimeOfDay
  final parts = initial.split(':');
  final initialTime = TimeOfDay(
    hour: int.tryParse(parts.isNotEmpty ? parts[0] : '08') ?? 8,
    minute: int.tryParse(parts.length > 1 ? parts[1] : '00') ?? 0,
  );

  return showTimePicker(
    context: context,
    initialTime: initialTime,
    helpText: title,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: AppColors.cardLight,
            hourMinuteShape: RoundedRectangleBorder(
              borderRadius: AppRadii.borderMd,
            ),
            dayPeriodShape: RoundedRectangleBorder(
              borderRadius: AppRadii.borderMd,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
          ),
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.textInverse,
            surface: AppColors.cardLight,
            onSurface: AppColors.primary,
          ),
        ),
        child: child!,
      );
    },
  ).then((picked) {
    if (picked == null) return null;
    final h = picked.hour.toString().padLeft(2, '0');
    final m = picked.minute.toString().padLeft(2, '0');
    return '$h:$m';
  });
}
