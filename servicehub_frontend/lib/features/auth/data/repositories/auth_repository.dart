import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../domain/models/auth_response.dart';
import '../../domain/models/user.dart';
import 'auth_exception.dart';

class AuthRepository {
  final ApiService apiService;

  AuthRepository({required this.apiService});

  // In AuthRepository
  Future<User> switchRole(String role) async {
    try {
      await apiService.authenticatedPost(
        '/user/switch-role',
        body: {'role': role},
      );
      // The switch-role response only contains roles and active_role,
      // so fetch the fresh user object to get all fields.
      return await me();
    } on ApiException catch (e) {
      throw AuthException(
        message: e.message,
        statusCode: e.statusCode,
        errors: e.errors,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(message: 'Failed to switch role: $e');
    }
  }

  /// Log in an existing user with email and password.
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await apiService.post(
        '/auth/login',
        body: {'email': email.trim(), 'password': password},
      );

      final dynamic data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return AuthResponse.fromJson(data);
      }
      throw const AuthException(
        message: 'Invalid response format from server.',
      );
    } on ApiException catch (e) {
      throw AuthException(
        message: e.message,
        statusCode: e.statusCode,
        errors: e.errors,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        message: 'An unexpected error occurred during login: $e',
      );
    }
  }

  /// Register a new customer.
  Future<AuthResponse> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await apiService.post(
        '/auth/register/customer',
        body: {
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      final dynamic data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return AuthResponse.fromJson(data);
      }
      throw const AuthException(
        message: 'Invalid response format from server.',
      );
    } on ApiException catch (e) {
      throw AuthException(
        message: e.message,
        statusCode: e.statusCode,
        errors: e.errors,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        message: 'An unexpected error occurred during registration: $e',
      );
    }
  }

  /// Fetch the currently authenticated user profile.
  Future<User> me() async {
    try {
      final response = await apiService.get('/auth/me', authenticated: true);

      final dynamic body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final userRaw = body['user'] ?? body['data'] ?? body;
        if (userRaw is Map<String, dynamic>) {
          return User.fromJson(userRaw);
        }
      }
      throw const AuthException(message: 'Could not parse user profile data.');
    } on ApiException catch (e) {
      throw AuthException(
        message: e.message,
        statusCode: e.statusCode,
        errors: e.errors,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(message: 'Failed to fetch user profile: $e');
    }
  }

  Future<User> becomeArtisan({
    required String professionalDescription,
    required int experienceYears,
  }) async {
    try {
      await apiService.authenticatedPost(
        '/user/become-artisan',
        body: {
          'professional_description': professionalDescription,
          'experience_years': experienceYears,
        },
      );
      // Fetch the full updated user (the become-artisan response doesn't
      // include the entire user payload).
      return await me();
    } on ApiException catch (e) {
      throw AuthException(
        message: e.message,
        statusCode: e.statusCode,
        errors: e.errors,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(message: 'Failed to become an artisan: $e');
    }
  }

  /// Log out the currently authenticated user.
  Future<void> logout() async {
    try {
      await apiService.post('/auth/logout', authenticated: true);
    } on ApiException catch (e) {
      // Even if server session invalidation fails, client will clear its token
      throw AuthException(
        message: e.message,
        statusCode: e.statusCode,
        errors: e.errors,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(message: 'Failed to log out: $e');
    }
  }
}
