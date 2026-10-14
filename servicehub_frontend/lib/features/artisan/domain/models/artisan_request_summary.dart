import 'package:flutter/foundation.dart';

import '../../../customer/domain/enums/service_request_status.dart';

/// A lightweight summary of a service request, as seen from the
/// artisan's side. Fetched from `GET /api/artisan/requests` (not yet
/// documented but consistent with the other routes).
@immutable
class ArtisanRequestSummary {
  const ArtisanRequestSummary({
    required this.id,
    required this.status,
    required this.serviceName,
    required this.description,
    required this.locationLabel,
    required this.customerFirstName,
    required this.customerId,
    required this.urgency,
    required this.createdAt,
    required this.pendingSince,
    required this.quotation,
  });

  final String id;
  final ServiceRequestStatus status;
  final String serviceName;
  final String description;
  final String locationLabel;
  final String customerFirstName;
  final String customerId;
  final String? urgency;
  final DateTime? createdAt;
  final DateTime? pendingSince;
  final Map<String, dynamic>? quotation;

  /// True when the artisan has been selected and needs to respond.
  bool get needsArtisanResponse =>
      status == ServiceRequestStatus.pendingArtisanResponse;

  /// True when the artisan has accepted and the job is in progress.
  bool get isActive =>
      status == ServiceRequestStatus.artisanApproved ||
      status == ServiceRequestStatus.booked ||
      status == ServiceRequestStatus.inProgress;

  /// A short, stable reference for the request.
  String get shortRef {
    if (id.length <= 6) return id.toUpperCase();
    return id.substring(id.length - 6).toUpperCase();
  }

  factory ArtisanRequestSummary.fromJson(Map<String, dynamic> json) {
    final serviceJson = json['service'] as Map<String, dynamic>?;
    final locationJson = json['location'] as Map<String, dynamic>?;
    final customerJson = json['customer'] as Map<String, dynamic>?;

    return ArtisanRequestSummary(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      status: ServiceRequestStatus.fromString(json['status']?.toString()),
      serviceName: serviceJson?['name']?.toString() ?? 'Service',
      description: json['description']?.toString() ?? '',
      locationLabel: locationJson?['label']?.toString() ?? 'Location not set',
      customerFirstName: customerJson?['first_name']?.toString() ??
          customerJson?['name']?.toString().split(' ').first ??
          'Customer',
      customerId: customerJson?['id']?.toString() ?? '',
      urgency: json['urgency']?.toString(),
      createdAt: _parseDate(json['created_at']),
      pendingSince: _parseDate(json['pending_since']),
      quotation: json['quotation'] as Map<String, dynamic>?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}