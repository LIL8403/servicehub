import 'package:flutter/material.dart';

import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../data/repositories/admin_user_repository.dart';
import '../catalog/modal_shell.dart';

class ChangeStatusResult {
  const ChangeStatusResult({
    required this.status,
    required this.reason,
  });

  final String status;
  final String reason;
}

Future<ChangeStatusResult?> showChangeStatusDialog(
  BuildContext context, {
  required AdminUser user,
  required bool isSelf,
  required bool isLastActiveAdmin,
}) {
  return showModalShell<ChangeStatusResult>(
    context: context,
    title: user.isSuspended
        ? 'Reactivate account'
        : 'Change account status',
    child: _ChangeStatusForm(
      user: user,
      isSelf: isSelf,
      isLastActiveAdmin: isLastActiveAdmin,
    ),
  );
}

class _ChangeStatusForm extends StatefulWidget {
  const _ChangeStatusForm({
    required this.user,
    required this.isSelf,
    required this.isLastActiveAdmin,
  });

  final AdminUser user;
  final bool isSelf;
  final bool isLastActiveAdmin;

  @override
  State<_ChangeStatusForm> createState() => _ChangeStatusFormState();
}

class _ChangeStatusFormState extends State<_ChangeStatusForm> {
  late final TextEditingController _reasonController;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    // Default the selection to the opposite of the current status.
    _selectedStatus = widget.user.isActive ? 'suspended' : 'active';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _reasonValid => _reasonController.text.trim().length >= 5;

  bool get _canSubmit {
    if (widget.isSelf) return false;
    if (!_reasonValid) return false;
    if (widget.isLastActiveAdmin && _selectedStatus == 'suspended') {
      return false;
    }
    return _selectedStatus != widget.user.status;
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.pop(
      context,
      ChangeStatusResult(
        status: _selectedStatus,
        reason: _reasonController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // User summary block
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.user.initials,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.user.contactLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'NEW STATUS',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        _statusRadio(
          value: 'active',
          title: 'Active',
          helper: 'Account is in good standing.',
        ),
        const SizedBox(height: 12),
        _statusRadio(
          value: 'suspended',
          title: 'Suspended',
          helper:
              'Tokens revoked. Artisan profile hidden from customers.',
          disabled: widget.isLastActiveAdmin,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'REASON',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.warningTint,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Mandatory',
                style: AppTypography.caption.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          minLines: 3,
          maxLength: 500,
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
            hintText:
                "Explain why you are changing this account's status. "
                'Minimum 5 characters.',
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
        Row(
          children: [
            Expanded(
              child: Text(
                'Audit record will cite administrator identity',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
            Text(
              '${_reasonController.text.length} / 500',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        if (widget.isSelf) ...[
          const SizedBox(height: 16),
          _infoBox(
            icon: Icons.info_outline,
            color: AppColors.textMuted,
            text:
                'You cannot change your own account status. Ask another '
                'administrator to do it.',
          ),
        ],
        if (widget.isLastActiveAdmin) ...[
          const SizedBox(height: 16),
          _infoBox(
            icon: Icons.warning_amber_outlined,
            color: AppColors.warning,
            text:
                'This is the last active administrator. Suspending it '
                'would lock everyone out of the admin panel.',
          ),
        ],
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
                backgroundColor: _selectedStatus == 'suspended'
                    ? AppColors.secondary
                    : AppColors.primary,
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
                _selectedStatus == 'suspended'
                    ? 'Suspend account'
                    : 'Activate account',
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

  Widget _statusRadio({
    required String value,
    required String title,
    required String helper,
    bool disabled = false,
  }) {
    final selected = _selectedStatus == value;
    final borderColor = disabled
        ? AppColors.borderLight
        : (selected ? AppColors.secondary : AppColors.borderLight);
    final bg = selected && !disabled
        ? AppColors.cream.withValues(alpha: 0.2)
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: disabled
            ? null
            : () => setState(() => _selectedStatus = value),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected && !disabled
                        ? AppColors.secondary
                        : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: selected && !disabled
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodySmall.copyWith(
                        color: disabled
                            ? AppColors.textMuted
                            : AppColors.primary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      helper,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}