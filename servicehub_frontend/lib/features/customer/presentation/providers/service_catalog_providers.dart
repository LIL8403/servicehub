import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ServiceRef {
  const ServiceRef({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categorySlug,
    required this.slug,
  });

  final String id;
  final String name;
  final String categoryId;
  final String categorySlug;
  final String slug;
}

final serviceCatalogProvider = FutureProvider<List<ServiceRef>>((ref) async {
  final api = ref.watch(apiServiceProvider);

  try {
    final response = await api.get('/services');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (json['services'] as List?) ?? [];

    return list
        .whereType<Map<String, dynamic>>()
        .map((entry) {
          final category = entry['category'] as Map<String, dynamic>?;
          return ServiceRef(
            id: entry['_id']?.toString() ??
                entry['id']?.toString() ??
                '',
            name: entry['name']?.toString() ?? '',
            categoryId: entry['service_category_id']?.toString() ?? '',
            categorySlug: category?['slug']?.toString() ?? '',
            slug: entry['slug']?.toString() ?? '',
          );
        })
        .where((s) => s.id.isNotEmpty)
        .toList();
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(message: 'Failed to load services: $e');
  }
});

ServiceRef? findServiceByCategorySlug(
  List<ServiceRef> catalog,
  String slug,
) {
  for (final service in catalog) {
    if (service.slug == slug || service.categorySlug == slug) {
      return service;
    }
  }
  return null;
}