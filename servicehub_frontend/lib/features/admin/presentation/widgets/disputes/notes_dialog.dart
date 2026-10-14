import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../catalog/modal_shell.dart';

/// Generic notes-collecting modal for disputes.
///
/// Used by: Start review, Investigate, Await information, Return to
/// review, Reconcile.
Future<String?> showNotesDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required String hintText,
  Color? confirmColor,
}) {
  return showModalShell<String>(
    context: context,
    title: title,
    child: _NotesForm(
      confirmLabel: confirmLabel,
      hintText: hintText,
      confirmColor: confirmColor ?? AppColors.primary,
    ),
  );
}

class _NotesForm extends StatefulWidget {
  const _NotesForm({
    required this.confirmLabel,
    required this.hintText,
    required this.confirmColor,
  });

  final String confirmLabel;
  final String hintText;
  final Color confirmColor;

  @override
  State<_NotesForm> createState() => _NotesFormState();
}

class _NotesFormState extends State<_NotesForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid => _controller.text.trim().length >= 5;

  void _submit() {
    if (!_valid) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'NOTES',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          maxLines: 4,
          minLines: 4,
          maxLength: 2000,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.primary,
            fontSize: 13,
            height: 1.5,
          ),
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            contentPadding: const EdgeInsets.all(12),
            hintText: widget.hintText,
            hintStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppColors.cardLight,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_controller.text.length} / 2000',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
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
              onPressed: _valid ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.confirmColor,
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
                widget.confirmLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: _valid ? Colors.white : AppColors.disabledText,
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