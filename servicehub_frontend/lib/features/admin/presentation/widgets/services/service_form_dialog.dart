import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../data/repositories/admin_service_repository.dart';
import '../../providers/admin_category_providers.dart';
import '../catalog/modal_field.dart';
import '../catalog/modal_shell.dart';
import '../catalog/modal_toggle_row.dart';
import 'category_dropdown.dart';

/// Result of the service form dialog. `null` means cancelled.
class ServiceFormResult {
  const ServiceFormResult({
    required this.categoryId,
    required this.name,
    required this.description,
    required this.isActive,
  });

  final String categoryId;
  final String name;
  final String? description;
  final bool isActive;
}

Future<ServiceFormResult?> showServiceFormDialog(
  BuildContext context, {
  AdminService? existing,
}) {
  return showModalShell<ServiceFormResult>(
    context: context,
    title: existing == null ? 'New service' : 'Edit service',
    titleIcon: existing == null ? null : Icons.edit_outlined,
    child: _ServiceForm(existing: existing),
  );
}

class _ServiceForm extends ConsumerStatefulWidget {
  const _ServiceForm({this.existing});

  final AdminService? existing;

  @override
  ConsumerState<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends ConsumerState<_ServiceForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String? _categoryId;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _descriptionController =
        TextEditingController(text: e?.description ?? '');
    _categoryId = e?.categoryId;
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
      _nameController.text.trim().length <= 100 &&
      _categoryId != null;

  void _submit() {
    if (!_canSubmit) return;
    Navigator.pop(
      context,
      ServiceFormResult(
        categoryId: _categoryId!,
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
    // Ensure categoryId is set once categories load — for a new
    // service, default to the first category.
    final categoriesAsync = ref.watch(adminCategoriesProvider);
    categoriesAsync.whenData((categories) {
      if (_categoryId == null && categories.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _categoryId == null) {
            setState(() => _categoryId = categories.first.id);
          }
        });
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ModalField(
          label: 'Name',
          controller: _nameController,
          hintText: 'e.g. Pipe repair',
          maxLength: 100,
          helperText: 'The customer-facing name. 2–100 characters.',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'CATEGORY',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            CategoryDropdown(
              selectedId: _categoryId,
              onChanged: (id) => setState(() => _categoryId = id),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ModalField(
          label: 'Description',
          controller: _descriptionController,
          hintText:
              'Optional. Describe what this service covers.',
          multiline: true,
          maxLength: 2000,
          showCounter: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        ModalToggleRow(
          title: 'Active',
          helper:
              'Inactive services are hidden from customers and artisans.',
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
                    ? 'Create service'
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