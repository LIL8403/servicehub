import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_exception.dart';
import '../providers/auth_providers.dart';

class RegisterState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, String> fieldErrors;

  const RegisterState({
    this.isLoading = false,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  RegisterState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, String>? fieldErrors,
    bool clearErrors = false,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      fieldErrors: clearErrors ? const {} : (fieldErrors ?? this.fieldErrors),
    );
  }
}

class RegisterViewModel extends StateNotifier<RegisterState> {
  final AuthNotifier _authNotifier;

  RegisterViewModel(this._authNotifier) : super(const RegisterState());

  bool validate({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String role,
    String? professionalDescription,
    int? experienceYears,
  }) {
    final errors = <String, String>{};

    if (name.trim().isEmpty) {
      errors['name'] = 'Please enter your full name.';
    }

    if (email.trim().isEmpty) {
      errors['email'] = 'Please enter your email address.';
    } else if (!email.contains('@')) {
      errors['email'] = 'Please enter a valid email address.';
    }

    if (phone.trim().isEmpty) {
      errors['phone'] = 'Please enter your phone number.';
    }

    if (password.isEmpty) {
      errors['password'] = 'Please enter a password.';
    } else if (password.length < 8) {
      errors['password'] = 'Password must contain at least 8 characters.';
    }

    if (confirmPassword.isEmpty) {
      errors['password_confirmation'] = 'Please confirm your password.';
    } else if (password != confirmPassword) {
      errors['password_confirmation'] = 'Passwords do not match.';
    }

    if (role == 'artisan') {
      final desc = professionalDescription?.trim() ?? '';
      if (desc.isEmpty) {
        errors['professional_description'] =
            'Please describe your work (minimum 10 characters).';
      } else if (desc.length < 10) {
        errors['professional_description'] =
            'Please describe your work (minimum 10 characters).';
      }
      if (experienceYears == null) {
        errors['experience_years'] = 'Please enter your years of experience.';
      } else if (experienceYears < 0 || experienceYears > 60) {
        errors['experience_years'] =
            'Experience must be between 0 and 60 years.';
      }
    }

    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }

    state = state.copyWith(clearErrors: true);
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String role,
    String? professionalDescription,
    int? experienceYears,
  }) async {
    if (!validate(
      name: name,
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
      role: role,
      professionalDescription: professionalDescription,
      experienceYears: experienceYears,
    )) {
      return false;
    }

    state = state.copyWith(isLoading: true, clearErrors: true);

    try {
      if (role == 'artisan') {
        await _authNotifier.registerArtisan(
          name: name.trim(),
          email: email.trim(),
          phone: phone.trim(),
          password: password,
          passwordConfirmation: confirmPassword,
          professionalDescription: professionalDescription!.trim(),
          experienceYears: experienceYears!,
        );
      } else {
        await _authNotifier.registerCustomer(
          name: name.trim(),
          email: email.trim(),
          phone: phone.trim(),
          password: password,
          passwordConfirmation: confirmPassword,
        );
      }

      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      final backendErrors = <String, String>{};
      if (e.errors != null) {
        for (final entry in e.errors!.entries) {
          if (entry.value.isNotEmpty) {
            backendErrors[entry.key] = entry.value.first;
          }
        }
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.firstErrorMessage,
        fieldErrors: backendErrors,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'An unexpected error occurred during registration. Please try again.',
      );
      return false;
    }
  }

  void clearErrors() {
    state = state.copyWith(clearErrors: true);
  }
}

final registerViewModelProvider =
    StateNotifierProvider.autoDispose<RegisterViewModel, RegisterState>((ref) {
      final authNotifier = ref.watch(authStateProvider.notifier);
      return RegisterViewModel(authNotifier);
    });
