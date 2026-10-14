import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../view_models/register_view_model.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _professionalDescriptionController = TextEditingController();
  final _experienceYearsController = TextEditingController();

  String _role = 'customer';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _bioLength = 0;

  @override
  void initState() {
    super.initState();
    _professionalDescriptionController.addListener(_onBioChanged);
  }

  @override
  void dispose() {
    _professionalDescriptionController.removeListener(_onBioChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _professionalDescriptionController.dispose();
    _experienceYearsController.dispose();
    super.dispose();
  }

  void _onBioChanged() {
    if (_bioLength != _professionalDescriptionController.text.length) {
      setState(() {
        _bioLength = _professionalDescriptionController.text.length;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final experienceYears = _role == 'artisan'
        ? int.tryParse(_experienceYearsController.text.trim())
        : null;

    final success = await ref
        .read(registerViewModelProvider.notifier)
        .register(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          role: _role,
          professionalDescription: _role == 'artisan'
              ? _professionalDescriptionController.text
              : null,
          experienceYears: experienceYears,
        );

    if (!success || !mounted) return;

    // The router's redirect will fire once the auth state settles and
    // route the user to their homeRoute. But in case the redirect is
    // suppressed (or delayed), we navigate explicitly to make the
    // intent clear.
    if (_role == 'artisan') {
      context.go('/artisan-home/profile/verification');
    } else {
      context.go('/customer-home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerViewModelProvider);
    final fieldErrors = registerState.fieldErrors;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: SvgPicture.asset(
                        'assets/brand/logo_symbol.svg',
                        width: 48,
                        height: 48,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    Text(
                      'Join ServiceHUB',
                      textAlign: TextAlign.center,
                      style: AppTypography.h2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create your account in a few steps.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _roleSelector(),
                    const SizedBox(height: AppSpacing.lg),
                    _field(
                      label: 'FULL NAME',
                      controller: _nameController,
                      hint: 'e.g. Jean Mbarga',
                      icon: Icons.person_outline,
                      errorText: fieldErrors['name'],
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _field(
                      label: 'EMAIL ADDRESS',
                      controller: _emailController,
                      hint: 'you@example.com',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      errorText: fieldErrors['email'],
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email address.';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _field(
                      label: 'PHONE NUMBER',
                      controller: _phoneController,
                      hint: '+237 6XX XXX XXX',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      errorText: fieldErrors['phone'],
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _field(
                      label: 'PASSWORD',
                      controller: _passwordController,
                      hint: 'At least 8 characters',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      errorText: fieldErrors['password'],
                      textInputAction: TextInputAction.next,
                      suffixIcon: IconButton(
                        iconSize: 20,
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password.';
                        }
                        if (value.length < 8) {
                          return 'Password must contain at least 8 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _field(
                      label: 'CONFIRM PASSWORD',
                      controller: _confirmPasswordController,
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      errorText: fieldErrors['password_confirmation'],
                      textInputAction: _role == 'artisan'
                          ? TextInputAction.next
                          : TextInputAction.done,
                      suffixIcon: IconButton(
                        iconSize: 20,
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password.';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),
                    if (_role == 'artisan') ...[
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.borderLight,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'PROFESSIONAL INFORMATION',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm + 2),
                      _bioField(fieldErrors['professional_description']),
                      const SizedBox(height: AppSpacing.md),
                      _experienceField(fieldErrors['experience_years']),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (registerState.errorMessage != null) ...[
                      _errorBanner(registerState.errorMessage!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: registerState.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textInverse,
                          disabledBackgroundColor: AppColors.disabledBg,
                          disabledForegroundColor: AppColors.disabledText,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: registerState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.textInverse,
                                  ),
                                ),
                              )
                            : Text(
                                'Create account',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textInverse,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'Sign in',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'I AM A...',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _roleCard(
                value: 'customer',
                title: 'Customer',
                subtitle: "I'm hiring an artisan",
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _roleCard(
                value: 'artisan',
                title: 'Artisan',
                subtitle: 'I offer services',
                icon: Icons.handyman_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _roleCard({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _role == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _role = value),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.cream.withValues(alpha: 0.3)
                : AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.borderLight,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.cream
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 18,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              if (selected)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? errorText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontSize: 14,
          ),
          decoration: _inputDecoration(
            hint: hint,
            icon: icon,
            errorText: errorText,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _bioField(String? errorText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PROFESSIONAL DESCRIPTION',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _professionalDescriptionController,
          maxLines: 4,
          minLines: 4,
          maxLength: 2000,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontSize: 13,
            height: 1.5,
          ),
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            hintText:
                'Describe what you do, your skills, and your years of '
                'experience. Minimum 10 characters.',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppColors.cardLight,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null
                    ? AppColors.error
                    : AppColors.borderLight,
              ),
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
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: AppColors.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  errorText,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$_bioLength / 2000',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _experienceField(String? errorText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'YEARS OF EXPERIENCE',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _experienceYearsController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontSize: 14,
          ),
          decoration: _inputDecoration(
            hint: 'e.g. 5',
            icon: Icons.work_history_outlined,
            errorText: errorText,
          ),
          validator: (value) {
            if (_role != 'artisan') return null;
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your years of experience.';
            }
            final n = int.tryParse(value.trim());
            if (n == null || n < 0 || n > 60) {
              return 'Experience must be between 0 and 60 years.';
            }
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      hintText: hint,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textMuted,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      errorText: errorText,
      filled: true,
      fillColor: AppColors.cardLight,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: errorText != null ? AppColors.error : AppColors.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
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
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
