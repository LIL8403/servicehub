import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_service.dart';
import '../../../../core/api/token_storage.dart';
import '../../data/repositories/auth_exception.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/user.dart';

// --- Auth States ---

sealed class AuthState {
  const AuthState();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

extension AuthStateX on AuthState {
  bool get isAuthenticated => this is AuthAuthenticated;
  bool get isLoading => this is AuthLoading;
  User? get user =>
      this is AuthAuthenticated ? (this as AuthAuthenticated).user : null;

  /// The route the user should land on for their current active role.
  String get homeRoute {
    final u = user;
    if (u == null) return '/landing';
    switch (u.activeRole) {
      case 'artisan':
        return '/artisan-home';
      case 'admin':
        return '/admin/dashboard';
      default:
        return '/customer-home';
    }
  }
}

// --- Auth Notifier ---

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repository;
  final TokenStorage tokenStorage;

  AuthNotifier({required this.repository, required this.tokenStorage})
    : super(const AuthLoading());

  Future<void> checkAuth() async {
    final token = await tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      state = const AuthUnauthenticated();
      return;
    }

    try {
      final user = await repository.me();
      state = AuthAuthenticated(user);
    } catch (_) {
      await tokenStorage.deleteToken();
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final authResponse = await repository.login(email, password);
      await tokenStorage.saveToken(authResponse.token);
      state = AuthAuthenticated(authResponse.user);
    } on AuthException catch (e) {
      state = AuthError(e.firstErrorMessage);
      rethrow;
    } catch (e) {
      final message = 'Login failed: $e';
      state = AuthError(message);
      throw AuthException(message: message);
    }
  }

  Future<void> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = const AuthLoading();
    try {
      final authResponse = await repository.registerCustomer(
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      await tokenStorage.saveToken(authResponse.token);
      state = AuthAuthenticated(authResponse.user);
    } on AuthException catch (e) {
      state = AuthError(e.firstErrorMessage);
      rethrow;
    } catch (e) {
      final message = 'Registration failed: $e';
      state = AuthError(message);
      throw AuthException(message: message);
    }
  }

  /// Registers a new artisan in one atomic flow: creates the base
  /// customer account, grants the artisan role, then sets the auth
  /// state ONCE at the end. This prevents the router from redirecting
  /// mid-flow (which would dispose the register view model).
  Future<void> registerArtisan({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String professionalDescription,
    required int experienceYears,
  }) async {
    state = const AuthLoading();
    try {
      // Step 1: register the base account (token is stored internally).
      final authResponse = await repository.registerCustomer(
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      await tokenStorage.saveToken(authResponse.token);

      // Step 2: immediately grant the artisan role. The auth state is
      // still AuthLoading, so no router redirect fires yet.
      final artisanUser = await repository.becomeArtisan(
        professionalDescription: professionalDescription,
        experienceYears: experienceYears,
      );

      // Step 3: the flow is complete — now set the state. The router
      // will fire once, landing the user on /artisan-home.
      state = AuthAuthenticated(artisanUser);
    } on AuthException catch (e) {
      state = AuthError(e.firstErrorMessage);
      rethrow;
    } catch (e) {
      final message = 'Registration failed: $e';
      state = AuthError(message);
      throw AuthException(message: message);
    }
  }

  /// Switches the user's active role between `customer` and `artisan`.
  ///
  /// The backend validates that the requested role is assigned to the
  /// account. On failure, the previous authenticated state is preserved
  /// so the app stays usable.
  Future<void> switchRole(String role) async {
    final current = state;
    if (current is! AuthAuthenticated) return;

    try {
      final updated = await repository.switchRole(role);
      state = AuthAuthenticated(updated);
    } catch (e) {
      // Keep the user logged in; just don't switch.
      state = AuthAuthenticated(current.user);
      rethrow;
    }
  }

  Future<void> becomeArtisan({
    required String professionalDescription,
    required int experienceYears,
  }) async {
    final current = state;
    if (current is! AuthAuthenticated) return;

    try {
      final updated = await repository.becomeArtisan(
        professionalDescription: professionalDescription,
        experienceYears: experienceYears,
      );
      state = AuthAuthenticated(updated);
    } catch (e) {
      state = AuthAuthenticated(current.user);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await repository.logout();
    } catch (_) {
      // Clear local credentials regardless of server error.
    } finally {
      await tokenStorage.deleteToken();
      state = const AuthUnauthenticated();
    }
  }
}

// --- Providers ---

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return const TokenStorage();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiService(tokenStorage: tokenStorage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthRepository(apiService: apiService);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(repository: repository, tokenStorage: tokenStorage);
});
