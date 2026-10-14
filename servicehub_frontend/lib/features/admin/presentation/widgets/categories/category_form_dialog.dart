import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../data/repositories/admin_category_repository.dart';
import '../catalog/modal_field.dart';
import '../catalog/modal_shell.dart';
import '../catalog/modal_toggle_row.dart';

/// Result of the form dialog. `null` means the user cancelled.
class CategoryFormResult {
  const CategoryFormResult({
    required this.name,
    required this.description,
    required this.isActive,
  });

  final String name;
  final String? description;
  final bool isActive;
}

Future<CategoryFormResult?> showCategoryFormDialog(
  BuildContext context, {
  AdminCategory? existing,
}) {
  return showModalShell<CategoryFormResult>(
    context: context,
    title: existing == null ? 'New category' : 'Edit category',
    titleIcon: existing == null ? null : Icons.edit_outlined,
    child: _CategoryForm(existing: existing),
  );
}

class _CategoryForm extends StatefulWidget {
  const _CategoryForm({this.existing});

  final AdminCategory? existing;

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _descriptionController =
        TextEditingController(text: e?.description ?? '');
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().length >= 2 &&
      _nameController.text.trim().length <= 100;

  void _submit() {
    if (!_canSubmit) return;
    Navigator.pop(
      context,
      CategoryFormResult(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ModalField(
          label: 'Name',
          controller: _nameController,
          hintText: 'e.g. Plumbing',
          maxLength: 100,
          helperText:
              'The customer-facing category name. 2–100 characters. '
              'Must be unique.',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        ModalField(
          label: 'Description',
          controller: _descriptionController,
          hintText: 'Optional. Describe what this category covers.',
          multiline: true,
          maxLength: 2000,
          showCounter: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        ModalToggleRow(
          title: 'Active',
          helper: 'Inactive categories are hidden from customers.',
          value: _isActive,
          onChanged: (v) => setState(() => _isActive = v),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 40),
              ),
              child: Text(
                'Cancel',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.disabledBg,
                disabledForegroundColor: AppColors.disabledText,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                minimumSize: const Size(0, 40),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                widget.existing == null
                    ? 'Create category'
                    : 'Save changes',
                style: AppTypography.bodySmall.copyWith(
                  color: _canSubmit
                      ? Colors.white
                      : AppColors.disabledText,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}