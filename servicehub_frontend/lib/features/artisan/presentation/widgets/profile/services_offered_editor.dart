import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';

/// A single service offering the artisan has selected.
class SelectedService {
  const SelectedService({
    required this.referenceId,
    required this.name,
  });

  final String referenceId;
  final String name;
}

/// Renders the services offered list with a remove button per row and
/// an "Add service" text button at the bottom. When the list is empty
/// it shows the dashed empty-state CTA from the mockup.
class ServicesOfferedEditor extends StatelessWidget {
  const ServicesOfferedEditor({
    super.key,
    required this.services,
    required this.onRemove,
    required this.onAdd,
    this.maxServices = 20,
  });

  final List<SelectedService> services;
  final void Function(SelectedService) onRemove;
  final VoidCallback onAdd;
  final int maxServices;

  @override
  Widget build(BuildContext context) {
    final canAdd = services.length < maxServices;

    if (services.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'No services added yet',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          _dashedAddButton(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < services.length; i++) ...[
          _serviceRow(services[i]),
          if (i < services.length - 1)
            Container(
              height: 1,
              color: AppColors.borderLight,
            ),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (canAdd) _textAddButton(),
      ],
    );
  }

  Widget _serviceRow(SelectedService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.work_outline,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Text(
              service.name,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
            icon: const Icon(Icons.close, color: AppColors.textMuted),
            onPressed: () => onRemove(service),
          ),
        ],
      ),
    );
  }

  Widget _dashedAddButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onAdd,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.6),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add,
                size: 20,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Add service',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textAddButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(
                Icons.add,
                size: 20,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Add service',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}