import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_exception.dart';
import '../providers/auth_providers.dart';

class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final String? emailError;
  final String? passwordError;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.emailError,
    this.passwordError,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? emailError,
    String? passwordError,
    bool clearErrors = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      emailError: clearErrors ? null : (emailError ?? this.emailError),
      passwordError: clearErrors ? null : (passwordError ?? this.passwordError),
    );
  }
}

class LoginViewModel extends StateNotifier<LoginState> {
  final AuthNotifier _authNotifier;

  LoginViewModel(this._authNotifier) : super(const LoginState());

  bool validate(String email, String password) {
    String? emailErr;
    String? passwordErr;

    if (email.trim().isEmpty) {
      emailErr = 'Please enter your email address.';
    } else if (!email.contains('@')) {
      emailErr = 'Please enter a valid email address.';
    }

    if (password.isEmpty) {
      passwordErr = 'Please enter your password.';
    }

    if (emailErr != null || passwordErr != null) {
      state = state.copyWith(
        emailError: emailErr,
        passwordError: passwordErr,
      );
      return false;
    }

    state = state.copyWith(clearErrors: true);
    return true;
  }

  Future<bool> login(String email, String password) async {
    if (!validate(email, password)) {
      return false;
    }

    state = state.copyWith(isLoading: true, clearErrors: true);
    try {
      await _authNotifier.login(email.trim(), password);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.firstErrorMessage,
        emailError: e.fieldError('email'),
        passwordError: e.fieldError('password'),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  void clearErrors() {
    state = state.copyWith(clearErrors: true);
  }
}

final loginViewModelProvider =
    StateNotifierProvider.autoDispose<LoginViewModel, LoginState>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);
  return LoginViewModel(authNotifier);
});
