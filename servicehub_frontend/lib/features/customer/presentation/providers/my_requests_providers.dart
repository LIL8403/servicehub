import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/enums/service_request_status.dart';
import '../../domain/models/service_request.dart';

/// A lightweight summary of a service request, used for the list on
/// the customer home page. The full [ServiceRequest] is fetched again
/// when the user taps a row and opens the tracking screen.
class RequestListItem {
  const RequestListItem({
    required this.id,
    required this.status,
    required this.serviceName,
    required this.description,
    required this.locationLabel,
    required this.createdAt,
  });

  final String id;
  final ServiceRequestStatus status;
  final String serviceName;
  final String description;
  final String locationLabel;
  final DateTime? createdAt;

  /// A short, human-stable reference for the request.
  String get shortRef {
    if (id.length <= 6) return id.toUpperCase();
    return id.substring(id.length - 6).toUpperCase();
  }

  factory RequestListItem.fromJson(Map<String, dynamic> json) {
    final serviceJson = json['service'] as Map<String, dynamic>?;
    final locationJson = json['location'] as Map<String, dynamic>?;

    return RequestListItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      status: ServiceRequestStatus.fromString(json['status']?.toString()),
      serviceName: serviceJson?['name']?.toString() ?? 'Service',
      description: json['description']?.toString() ?? '',
      locationLabel: locationJson?['label']?.toString() ?? 'Location not set',
      createdAt: parseDateTime(json['created_at']),
    );
  }
}

/// Fetches all service requests belonging to the current customer.
///
/// Auto-disposes, so returning to the home page after a status change
/// re-fetches the list with the latest data.
final myRequestsProvider = FutureProvider.autoDispose<List<RequestListItem>>(
  (ref) async {
    final api = ref.watch(apiServiceProvider);

    try {
      final response =
          await api.authenticatedGet('/customer/service-requests');

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['service_requests'] as List?) ?? const [];

      return list
          .whereType<Map<String, dynamic>>()
          .map(RequestListItem.fromJson)
          .where((r) => r.id.isNotEmpty)
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load your requests: $e');
    }
  },
);