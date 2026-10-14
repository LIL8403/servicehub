import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isEnglish = currentLocale.languageCode == 'en';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LanguageOption(
          label: 'EN',
          isActive: isEnglish,
          onTap: () => ref
              .read(localeProvider.notifier)
              .setLocale(const Locale('en')),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            '|',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.borderLight,
            ),
          ),
        ),
        _LanguageOption(
          label: 'FR',
          isActive: !isEnglish,
          onTap: () => ref
              .read(localeProvider.notifier)
              .setLocale(const Locale('fr')),
        ),
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: AppTypography.bodySmall.copyWith(
          color: isActive ? AppColors.secondary : AppColors.textMuted,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}