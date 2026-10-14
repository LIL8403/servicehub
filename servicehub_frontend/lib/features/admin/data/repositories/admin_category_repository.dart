import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';

/// A service category as returned by the admin endpoint.
class AdminCategory {
  const AdminCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.isActive,
    required this.serviceCount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final bool isActive;
  final int serviceCount;
  final DateTime? createdAt;

  factory AdminCategory.fromJson(Map<String, dynamic> json) {
    final services = json['services'];
    final count = services is List ? services.length : 0;

    return AdminCategory(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isActive: json['is_active'] != false,
      serviceCount: count,
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

class AdminCategoryRepository {
  AdminCategoryRepository({required this.apiService});

  final ApiService apiService;

  Future<List<AdminCategory>> fetchAll() async {
    try {
      final response =
          await apiService.authenticatedGet('/admin/service-categories');
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['categories'] as List?) ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(AdminCategory.fromJson)
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load categories: $e');
    }
  }

  Future<void> create({
    required String name,
    required String? description,
    required bool isActive,
  }) async {
    try {
      await apiService.authenticatedPost(
        '/admin/service-categories',
        body: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
          'is_active': isActive,
        },
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to create category: $e');
    }
  }

  Future<void> update({
    required String id,
    required String name,
    required String? description,
    required bool isActive,
  }) async {
    try {
      await apiService.authenticatedPatch(
        '/admin/service-categories/$id',
        body: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
          'is_active': isActive,
        },
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to update category: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await apiService.authenticatedDelete(
        '/admin/service-categories/$id',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to delete category: $e');
    }
  }
}