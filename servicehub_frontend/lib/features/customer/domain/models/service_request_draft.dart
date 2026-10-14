import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import '../enums/urgency_level.dart';

/// Holds the mutable state of a service request as it is being built
/// through the multi-step wizard. This is a plain data class; the wizard's
/// provider copies it via [copyWith] on every edit.
@immutable
class ServiceRequestDraft {
  const ServiceRequestDraft({
    this.categoryId,
    this.serviceId,
    this.description = '',
    this.photoFiles = const [],
    this.urgency,
    this.aiAssistEnabled = false,
    this.locationLatitude,
    this.locationLongitude,
    this.formattedAddress,
    this.preferredDate,
    this.preferredStartTime,
    this.preferredEndTime,
    this.isFlexible = false,
    this.additionalNotes = '',
  });

  final String? categoryId;
  final String? serviceId;
  final String description;
  final List<XFile> photoFiles;
  final UrgencyLevel? urgency;
  final bool aiAssistEnabled;

  final double? locationLatitude;
  final double? locationLongitude;
  final String? formattedAddress;

  final DateTime? preferredDate;
  final String? preferredStartTime;
  final String? preferredEndTime;
  final bool isFlexible;
  final String additionalNotes;

  /// True when Step 1 is valid enough to continue.
  bool get isStep1Valid =>
      categoryId != null &&
      serviceId != null &&
      description.trim().isNotEmpty &&
      urgency != null;

  /// Valid when a formatted address is present, whether coordinates
  /// are real or null. Matches the backend's `required_without`
  /// rule — address alone is enough for the backend to geocode.
  bool get isStep2Valid {
    final address = formattedAddress?.trim() ?? '';
    return address.isNotEmpty;
  }

  /// True when Step 3 is valid enough to continue.
  bool get isStep3Valid {
    if (isFlexible) return true;
    return preferredDate != null &&
        preferredStartTime != null &&
        preferredEndTime != null;
  }

  ServiceRequestDraft copyWith({
    String? categoryId,
    String? serviceId,
    String? description,
    List<XFile>? photoFiles,
    UrgencyLevel? urgency,
    bool? aiAssistEnabled,
    double? locationLatitude,
    double? locationLongitude,
    String? formattedAddress,
    DateTime? preferredDate,
    String? preferredStartTime,
    String? preferredEndTime,
    bool? isFlexible,
    String? additionalNotes,
  }) {
    return ServiceRequestDraft(
      categoryId: categoryId ?? this.categoryId,
      serviceId: serviceId ?? this.serviceId,
      description: description ?? this.description,
      photoFiles: photoFiles ?? this.photoFiles,
      urgency: urgency ?? this.urgency,
      aiAssistEnabled: aiAssistEnabled ?? this.aiAssistEnabled,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredStartTime: preferredStartTime ?? this.preferredStartTime,
      preferredEndTime: preferredEndTime ?? this.preferredEndTime,
      isFlexible: isFlexible ?? this.isFlexible,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }
}
