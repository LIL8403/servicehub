import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';

class OfferingFormResult {
  const OfferingFormResult({
    required this.serviceId,
    this.startingPrice,
    this.description,
  });

  final String serviceId;
  final double? startingPrice;
  final String? description;
}

/// Opens the add/edit sheet. For editing, pass the initial values.
/// Returns null when the user cancels.
Future<OfferingFormResult?> showOfferingFormSheet(
  BuildContext context, {
  required List<OfferingServiceOption> services,
  String? initialServiceId,
  double? initialStartingPrice,
  String? initialDescription,
  bool isEditing = false,
}) {
  return showModalBottomSheet<OfferingFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OfferingFormSheet(
      services: services,
      initialServiceId: initialServiceId,
      initialStartingPrice: initialStartingPrice,
      initialDescription: initialDescription,
      isEditing: isEditing,
    ),
  );
}

class OfferingServiceOption {
  const OfferingServiceOption({
    required this.id,
    required this.name,
    required this.categoryName,
  });

  final String id;
  final String name;
  final String categoryName;
}

class _OfferingFormSheet extends StatefulWidget {
  const _OfferingFormSheet({
    required this.services,
    this.initialServiceId,
    this.initialStartingPrice,
    this.initialDescription,
    this.isEditing = false,
  });

  final List<OfferingServiceOption> services;
  final String? initialServiceId;
  final double? initialStartingPrice;
  final String? initialDescription;
  final bool isEditing;

  @override
  State<_OfferingFormSheet> createState() => _OfferingFormSheetState();
}

class _OfferingFormSheetState extends State<_OfferingFormSheet> {
  String? _serviceId;
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _serviceId = widget.initialServiceId;
    if (widget.initialStartingPrice != null) {
      _priceController.text = widget.initialStartingPrice!.round().toString();
    }
    _descriptionController.text = widget.initialDescription ?? '';
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_serviceId == null || _serviceId!.isEmpty) {
      setState(() => _error = 'Please pick a service.');
      return;
    }

    final priceText = _priceController.text.trim();
    double? price;
    if (priceText.isNotEmpty) {
      price = double.tryParse(priceText);
      if (price == null || price < 0) {
        setState(() => _error = 'Enter a valid starting price.');
        return;
      }
    }

    Navigator.of(context).pop(
      OfferingFormResult(
        serviceId: _serviceId!,
        startingPrice: price,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.isEditing
                            ? 'Edit service offering'
                            : 'Add a service',
                        style: AppTypography.h4.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label('Service'),
                      const SizedBox(height: 6),
                      _servicePicker(),
                      const SizedBox(height: AppSpacing.md),
                      _label('Starting price (optional)'),
                      const SizedBox(height: 6),
                      _priceField(),
                      const SizedBox(height: 6),
                      Text(
                        'A rough indication, not a binding quote. '
                        'Customers still receive a proper quotation.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _label('Short description (optional)'),
                      const SizedBox(height: 6),
                      _descriptionField(),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _errorBanner(_error!),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textInverse,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            widget.isEditing ? 'Save changes' : 'Add service',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textInverse,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _servicePicker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _serviceId,
          isExpanded: true,
          hint: Text(
            'Pick a service',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          items: widget.services
              .map(
                (s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(
                    '${s.categoryName} · ${s.name}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: widget.isEditing
              ? null
              : (v) => setState(() {
                  _serviceId = v;
                  _error = null;
                }),
        ),
      ),
    );
  }

  Widget _priceField() {
    return TextField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'e.g. 15000',
        suffixText: 'XAF',
        suffixStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        filled: true,
        fillColor: AppColors.cardLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _descriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 3,
      maxLength: 1000,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.primary,
        height: 1.4,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'A short line about what you offer for this service.',
        hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.cardLight,
        contentPadding: const EdgeInsets.all(12),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.errorTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
