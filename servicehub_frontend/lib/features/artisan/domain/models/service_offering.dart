import 'package:flutter/foundation.dart';

/// A single service the artisan has published, as stored on
/// `artisans.service_offerings`.
///
/// The backend uses `service_reference` for what the client calls
/// `serviceId`. We normalize that in [fromJson] so downstream code has
/// one name for the field.
@immutable
class ServiceOffering {
  const ServiceOffering({
    required this.offeringId,
    required this.serviceId,
    required this.isActive,
    this.startingPrice,
    this.description,
  });

  /// The Mongo-level unique id for this offering entry.
  final String offeringId;

  /// The referenced service (`services._id`).
  final String serviceId;

  final bool isActive;
  final double? startingPrice;
  final String? description;

  ServiceOffering copyWith({
    bool? isActive,
    double? startingPrice,
    String? description,
    bool clearStartingPrice = false,
    bool clearDescription = false,
  }) {
    return ServiceOffering(
      offeringId: offeringId,
      serviceId: serviceId,
      isActive: isActive ?? this.isActive,
      startingPrice: clearStartingPrice
          ? null
          : (startingPrice ?? this.startingPrice),
      description: clearDescription ? null : (description ?? this.description),
    );
  }

  factory ServiceOffering.fromJson(Map<String, dynamic> json) {
    return ServiceOffering(
      offeringId: json['offering_id']?.toString() ?? '',
      serviceId:
          (json['service_reference'] ?? json['service_id'])?.toString() ?? '',
      isActive: json['is_active'] == true,
      startingPrice: (json['starting_price'] as num?)?.toDouble(),
      description: json['description']?.toString(),
    );
  }
}
