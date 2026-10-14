import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';

/// The predefined set of units an artisan can choose from. Any value
/// not in this list can still be typed manually — the field is a
/// suggestion list, not a strict enum.
const List<String> kMaterialUnits = [
  'piece',
  'set',
  'metre',
  'square metre',
  'kilogram',
  'gram',
  'litre',
  'millilitre',
  'bag',
  'box',
  'roll',
  'sheet',
  'length',
  'hour',
];

/// A single editable material line in the materials proposal form.
class MaterialRowEditor extends StatefulWidget {
  const MaterialRowEditor({
    super.key,
    required this.index,
    required this.onChanged,
    required this.onRemoved,
  });

  final int index;
  final void Function({
    required String name,
    required double quantity,
    required String unit,
    required double unitCost,
  }) onChanged;
  final VoidCallback onRemoved;

  @override
  State<MaterialRowEditor> createState() => _MaterialRowEditorState();
}

class _MaterialRowEditorState extends State<MaterialRowEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitCostController;

  String _unit = 'piece';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
    _unitCostController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitCostController.dispose();
    super.dispose();
  }

  void _emit() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final unitCost = double.tryParse(_unitCostController.text) ?? 0;
    widget.onChanged(
      name: _nameController.text.trim(),
      quantity: quantity,
      unit: _unit,
      unitCost: unitCost,
    );
    setState(() {});
  }

  double get _lineTotal {
    final q = double.tryParse(_quantityController.text) ?? 0;
    final u = double.tryParse(_unitCostController.text) ?? 0;
    return q * u;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md - 4),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Material ${widget.index + 1}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onRemoved,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            onChanged: (_) => _emit(),
            textCapitalization: TextCapitalization.sentences,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
            ),
            decoration: InputDecoration(
              hintText: 'Item name (e.g. 20A circuit breaker)',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.cardLight,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.sm + 2,
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => _emit(),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Qty',
                    hintStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.cardLight,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: AppSpacing.sm + 2,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.borderMd,
                      borderSide:
                          const BorderSide(color: AppColors.borderLight),
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
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _UnitSelector(
                  value: _unit,
                  onChanged: (v) {
                    _unit = v;
                    _emit();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _unitCostController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (_) => _emit(),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Unit cost (XAF)',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.sm + 2,
                  right: 6,
                ),
                child: Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              filled: true,
              fillColor: AppColors.cardLight,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.sm + 2,
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
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Estimated cost',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                '${_money(_lineTotal)} XAF',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _money(double amount) {
    final rounded = amount.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) buf.write(',');
      buf.write(rounded[i]);
    }
    return buf.toString();
  }
}

/// A small dropdown-styled selector for the material unit. Uses a
/// MenuAnchor so it looks like a compact button rather than a full
/// Material dropdown, matching the compactness of the rest of the row.
class _UnitSelector extends StatelessWidget {
  const _UnitSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: kMaterialUnits
          .map(
            (unit) => MenuItemButton(
              onPressed: () => onChanged(unit),
              child: Text(
                unit,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          )
          .toList(),
      builder: (context, controller, _) {
        return GestureDetector(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: AppRadii.borderMd,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}