import 'package:flutter/foundation.dart';

import '../enums/service_request_status.dart';
import 'artisan_summary.dart';
import 'materials_proposal.dart';

/// A full representation of a service request as returned by
/// `GET /api/customer/service-requests/{id}`.
///
/// This model intentionally exposes only the fields the customer
/// tracking UI currently consumes. Fields like `quotation`, `materials`,
/// `completion`, and `inspection` are deferred until the corresponding
/// lifecycle views are built.
@immutable
class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.customerId,
    this.customer,
    required this.serviceId,
    required this.description,
    required this.status,
    required this.statusHistory,
    required this.selectionHistory,
    required this.aiAssistEnabled,
    required this.matchingAttempts,
    required this.imageAttachments,
    this.location,
    this.formattedAddress,
    this.preferredSchedule,
    this.createdAt,
    this.updatedAt,
    this.pendingSince,
    this.noArtisanReason,
    this.urgency,
    this.service,
    this.selectedArtisan,
    this.quotation,
    this.materials,
    this.completion,
  });

  final String id;
  final String customerId;
  final CustomerSnapshot? customer;
  final String serviceId;
  final String description;
  final ServiceRequestStatus status;
  final List<StatusHistoryEvent> statusHistory;
  final List<SelectionHistoryEvent> selectionHistory;
  final bool aiAssistEnabled;
  final int matchingAttempts;
  final List<ImageAttachment> imageAttachments;
  final Quotation? quotation;
  final MaterialsProposal? materials;
  final CompletionReport? completion;

  final GeoLocation? location;
  final String? formattedAddress;
  final PreferredSchedule? preferredSchedule;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? pendingSince;
  final String? noArtisanReason;
  final String? urgency;

  final ServiceSnapshot? service;
  final ArtisanSummary? selectedArtisan;

  /// True when an artisan has been chosen for this request.
  bool get hasArtisan => selectedArtisan != null;

  /// The most recent status-history event, if any.
  StatusHistoryEvent? get latestStatusEvent =>
      statusHistory.isEmpty ? null : statusHistory.last;

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    final serviceJson = json['service'] as Map<String, dynamic>?;
    final artisanJson = json['selected_artisan'] as Map<String, dynamic>?;
    final customerJson = json['customer'] as Map<String, dynamic>?;
    final locationJson = json['location'] as Map<String, dynamic>?;
    final scheduleJson = json['preferred_schedule'] as Map<String, dynamic>?;
    final historyJson = (json['status_history'] as List?) ?? const [];
    final selectionJson = (json['selection_history'] as List?) ?? const [];
    final imagesJson = (json['image_attachments'] as List?) ?? const [];

    return ServiceRequest(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customer: customerJson != null
          ? CustomerSnapshot.fromJson(customerJson)
          : null,
      serviceId: json['service_id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: ServiceRequestStatus.fromString(json['status']?.toString()),
      statusHistory: historyJson
          .whereType<Map<String, dynamic>>()
          .map(StatusHistoryEvent.fromJson)
          .toList(growable: false),
      selectionHistory: selectionJson
          .whereType<Map<String, dynamic>>()
          .map(SelectionHistoryEvent.fromJson)
          .toList(growable: false),
      aiAssistEnabled: json['ai_assist_enabled'] == true,
      matchingAttempts: (json['matching_attempts'] as num?)?.toInt() ?? 0,
      imageAttachments: imagesJson
          .whereType<Map<String, dynamic>>()
          .map(ImageAttachment.fromJson)
          .toList(growable: false),
      location: locationJson != null
          ? GeoLocation.fromJson(locationJson)
          : null,
      formattedAddress: json['formatted_address']?.toString(),
      preferredSchedule: scheduleJson != null
          ? PreferredSchedule.fromJson(scheduleJson)
          : null,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      pendingSince: parseDateTime(json['pending_since']),
      quotation: json['quotation'] is Map<String, dynamic>
          ? Quotation.fromJson(json['quotation'] as Map<String, dynamic>)
          : null,
      materials: json['materials'] is List
          ? MaterialsProposal.fromJsonList(json['materials'])
          : null,
      noArtisanReason: json['no_artisan_reason']?.toString(),
      urgency: json['urgency']?.toString(),
      completion: json['completion'] is Map<String, dynamic>
          ? CompletionReport.fromJson(
              json['completion'] as Map<String, dynamic>,
            )
          : null,
      service: serviceJson != null
          ? ServiceSnapshot.fromJson(serviceJson)
          : null,
      selectedArtisan: artisanJson != null
          ? ArtisanSummary.fromJson(artisanJson)
          : null,
    );
  }
}

// ============================================================
// Shared parsing helper (top-level so nested classes can reuse it)
// ============================================================

DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

// ============================================================
// Nested / Helper Models
// ============================================================

@immutable
class GeoLocation {
  const GeoLocation({this.label, this.type, this.coordinates});

  final String? label;
  final String? type;

  /// GeoJSON order: [longitude, latitude].
  final List<double>? coordinates;

  double? get longitude => _coordAt(0);
  double? get latitude => _coordAt(1);

  double? _coordAt(int index) {
    final coords = coordinates;
    if (coords == null || coords.length <= index) return null;
    return coords[index];
  }

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    final raw = (json['coordinates'] as List?) ?? const [];
    final coords = raw
        .whereType<num>()
        .map((n) => n.toDouble())
        .toList(growable: false);

    return GeoLocation(
      label: json['label']?.toString(),
      type: json['type']?.toString(),
      coordinates: coords.isEmpty ? null : coords,
    );
  }
}

@immutable
class PreferredSchedule {
  const PreferredSchedule({this.date, this.window, this.notes});

  final String? date;
  final String? window;
  final String? notes;

  bool get isFlexible => (window ?? '').toLowerCase() == 'flexible';

  /// A display-ready summary for the "Request details" card.
  /// Falls back to "Flexible" when the backend has recorded that choice.
  String get displayLabel {
    if (isFlexible) return 'Flexible';
    if (window != null && window!.isNotEmpty) return window!;
    if (date != null && date!.isNotEmpty) return date!;
    return 'Not specified';
  }

  factory PreferredSchedule.fromJson(Map<String, dynamic> json) {
    return PreferredSchedule(
      date: json['date']?.toString(),
      window: json['window']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

@immutable
class ServiceSnapshot {
  const ServiceSnapshot({
    required this.id,
    required this.name,
    required this.description,
    required this.slug,
    required this.serviceCategoryId,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final String slug;
  final String serviceCategoryId;
  final bool isActive;

  factory ServiceSnapshot.fromJson(Map<String, dynamic> json) {
    return ServiceSnapshot(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      serviceCategoryId: json['service_category_id']?.toString() ?? '',
      isActive: json['is_active'] == true,
    );
  }
}

@immutable
class StatusHistoryEvent {
  const StatusHistoryEvent({
    required this.status,
    required this.event,
    this.occurredAt,
    this.actorId,
    this.artisanId,
    this.reason,
  });

  final ServiceRequestStatus status;
  final String event;
  final DateTime? occurredAt;
  final String? actorId;
  final String? artisanId;
  final String? reason;

  factory StatusHistoryEvent.fromJson(Map<String, dynamic> json) {
    return StatusHistoryEvent(
      status: ServiceRequestStatus.fromString(json['status']?.toString()),
      event: json['event']?.toString() ?? '',
      occurredAt: parseDateTime(json['occurred_at']),
      actorId: json['actor_id']?.toString(),
      artisanId: json['artisan_id']?.toString(),
      reason: json['reason']?.toString(),
    );
  }
}

@immutable
class SelectionHistoryEvent {
  const SelectionHistoryEvent({
    required this.event,
    required this.artisanId,
    this.artisanName,
    this.occurredAt,
    this.reason,
  });

  final String event;
  final String artisanId;
  final String? artisanName;
  final DateTime? occurredAt;
  final String? reason;

  factory SelectionHistoryEvent.fromJson(Map<String, dynamic> json) {
    return SelectionHistoryEvent(
      event: json['event']?.toString() ?? '',
      artisanId: json['artisan_id']?.toString() ?? '',
      artisanName: json['artisan_name']?.toString(),
      occurredAt: parseDateTime(json['occurred_at']),
      reason: json['reason']?.toString(),
    );
  }
}

@immutable
class ImageAttachment {
  const ImageAttachment({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.size,
  });

  final String id;
  final String name;
  final String mimeType;
  final int size;

  factory ImageAttachment.fromJson(Map<String, dynamic> json) {
    return ImageAttachment(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class Quotation {
  const Quotation({
    required this.labourTotal,
    required this.materialsTotal,
    required this.grandTotal,
    this.scope,
    this.validUntil,
    this.status,
  });

  final double labourTotal;
  final double materialsTotal;
  final double grandTotal;
  final String? scope;
  final DateTime? validUntil;
  final String? status;

  /// True when the customer still needs to accept or reject the quote.
  bool get isPending =>
      (status ?? '').toLowerCase() == 'pending' ||
      status == null ||
      status!.isEmpty;

  factory Quotation.fromJson(Map<String, dynamic> json) {
    // The backend stores `labor_amount` (American spelling). Materials
    // are not yet part of the quotation shape — they get proposed
    // separately and approved on their own. We read `total` if it's
    // present; otherwise we fall back to the labour amount.
    final labour =
        (json['labor_amount'] as num?)?.toDouble() ??
        (json['labour_amount'] as num?)?.toDouble() ??
        0.0;

    final materials =
        (json['materials_amount'] as num?)?.toDouble() ??
        (json['materials_total'] as num?)?.toDouble() ??
        0.0;

    final total =
        (json['total'] as num?)?.toDouble() ??
        (json['grand_total'] as num?)?.toDouble() ??
        (labour + materials);

    return Quotation(
      labourTotal: labour,
      materialsTotal: materials,
      grandTotal: total,
      scope: json['scope']?.toString(),
      validUntil: parseDateTime(json['valid_until']),
      status: json['status']?.toString(),
    );
  }
}

@immutable
class CompletionReport {
  const CompletionReport({this.notes, this.reportedAt});

  final String? notes;
  final DateTime? reportedAt;

  factory CompletionReport.fromJson(Map<String, dynamic> json) {
    return CompletionReport(
      notes: json['notes']?.toString(),
      reportedAt: parseDateTime(json['reported_at']),
    );
  }
}

@immutable
class CustomerSnapshot {
  const CustomerSnapshot({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.hasPhoto,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String name;
  final bool hasPhoto;

  factory CustomerSnapshot.fromJson(Map<String, dynamic> json) {
    return CustomerSnapshot(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      hasPhoto: json['profile_photo'] != null,
    );
  }
}
