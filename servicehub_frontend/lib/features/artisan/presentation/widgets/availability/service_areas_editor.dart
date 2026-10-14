import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/models/availability.dart';

/// Cities multi-select with a free-text fallback.
///
/// Renders the fifteen supported cities as toggle chips. Any city
/// already stored that is not in the list appears as a chip too, so
/// nothing is silently dropped. Below the chips, a small input lets
/// the artisan add an unsupported city by name.
class ServiceAreasEditor extends StatefulWidget {
  const ServiceAreasEditor({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  State<ServiceAreasEditor> createState() => _ServiceAreasEditorState();
}

class _ServiceAreasEditorState extends State<ServiceAreasEditor> {
  final _customController = TextEditingController();
  late List<String> _current;

  @override
  void initState() {
    super.initState();
    _current = List<String>.from(widget.selected);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _toggle(String city) {
    setState(() {
      if (_current.contains(city)) {
        _current.remove(city);
      } else {
        _current.add(city);
      }
      widget.onChanged(_current);
    });
  }

  void _addCustom() {
    final value = _customController.text.trim();
    if (value.isEmpty) return;
    // Normalize casing so the chip reads cleanly. Matches how the
    // preset list is written.
    final normalized = value
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    if (_current.contains(normalized)) {
      _customController.clear();
      return;
    }
    setState(() {
      _current.add(normalized);
      widget.onChanged(_current);
      _customController.clear();
    });
  }

  /// Cities already selected that are not in the preset list.
  List<String> get _customSelected =>
      _current.where((c) => !kCameroonCities.contains(c)).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final city in kCameroonCities)
              _CityChip(
                label: city,
                selected: _current.contains(city),
                onTap: () => _toggle(city),
              ),
          ],
        ),
        if (_customSelected.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Other cities',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final city in _customSelected)
                _CityChip(
                  label: city,
                  selected: true,
                  onTap: () => _toggle(city),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addCustom(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  hintText: 'Add another city',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.cardLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadii.borderMd,
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadii.borderMd,
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 72,
              height: 44,
              child: ElevatedButton(
                onPressed: _addCustom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  shape: const StadiumBorder(),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Add'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Pick the cities where you take jobs. Customers in these '
          'areas can find you.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardLight,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 14, color: AppColors.textInverse),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: selected ? AppColors.textInverse : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
