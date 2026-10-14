import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';

/// A service as returned by the admin endpoint.
class AdminService {
  const AdminService({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.description,
    required this.isActive,
    required this.categoryName,
    required this.createdAt,
  });

  final String id;
  final String categoryId;
  final String name;
  final String slug;
  final String description;
  final bool isActive;
  final String categoryName;
  final DateTime? createdAt;

  factory AdminService.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;

    return AdminService(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      categoryId: json['service_category_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isActive: json['is_active'] != false,
      categoryName: category?['name']?.toString() ?? '—',
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

class AdminServiceRepository {
  AdminServiceRepository({required this.apiService});

  final ApiService apiService;

  Future<List<AdminService>> fetchAll() async {
    try {
      final response =
          await apiService.authenticatedGet('/admin/services');
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['services'] as List?) ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(AdminService.fromJson)
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load services: $e');
    }
  }

  Future<void> create({
    required String categoryId,
    required String name,
    required String? description,
    required bool isActive,
  }) async {
    try {
      await apiService.authenticatedPost(
        '/admin/services',
        body: {
          'service_category_id': categoryId,
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
          'is_active': isActive,
        },
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to create service: $e');
    }
  }

  Future<void> update({
    required String id,
    required String categoryId,
    required String name,
    required String? description,
    required bool isActive,
  }) async {
    try {
      await apiService.authenticatedPatch(
        '/admin/services/$id',
        body: {
          'service_category_id': categoryId,
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
          'is_active': isActive,
        },
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to update service: $e');
    }
  }
}