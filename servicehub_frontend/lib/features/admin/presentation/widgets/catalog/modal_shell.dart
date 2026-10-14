import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// The outer container for all admin catalog modals.
///
/// Provides a semi-transparent scrim, a centered white card with a
/// title row and a close button, and a content area.
///
/// Usage: `showModalShell(context, title: '...', child: Column(...))`
/// returns whatever the child passes to `Navigator.pop`.
Future<T?> showModalShell<T>({
  required BuildContext context,
  required String title,
  IconData? titleIcon,
  required Widget child,
  double width = 480,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.5),
    useRootNavigator: false,
    builder: (ctx) => _ModalShell(
      title: title,
      titleIcon: titleIcon,
      width: width,
      child: child,
    ),
  );
}

class _ModalShell extends StatelessWidget {
  const _ModalShell({
    required this.title,
    required this.titleIcon,
    required this.width,
    required this.child,
  });

  final String title;
  final IconData? titleIcon;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (titleIcon != null) ...[
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          titleIcon,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.h4.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        hoverColor: AppColors.bgLight,
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Flexible(child: SingleChildScrollView(child: child)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
