class ServiceRequestTracking {
  const ServiceRequestTracking({
    required this.request,
    required this.artisan,
    required this.pendingResponse,
    required this.nextAction,
    required this.permissions,
    required this.timeline,
  });

  final TrackingRequest request;
  final TrackingArtisan? artisan;
  final PendingArtisanResponse? pendingResponse;
  final TrackingAction? nextAction;
  final TrackingPermissions permissions;
  final List<TrackingTimelineEntry> timeline;

  factory ServiceRequestTracking.fromJson(Map<String, dynamic> json) {
    return ServiceRequestTracking(
      request: TrackingRequest.fromJson(_map(json['service_request'])),
      artisan: json['selected_artisan'] is Map
          ? TrackingArtisan.fromJson(_map(json['selected_artisan']))
          : null,
      pendingResponse: json['pending_response'] is Map
          ? PendingArtisanResponse.fromJson(_map(json['pending_response']))
          : null,
      nextAction: json['next_action'] is Map
          ? TrackingAction.fromJson(_map(json['next_action']))
          : null,
      permissions: TrackingPermissions.fromJson(_map(json['permissions'])),
      timeline: _list(json['timeline'])
          .map((entry) => TrackingTimelineEntry.fromJson(_map(entry)))
          .toList(),
    );
  }
}

class TrackingRequest {
  const TrackingRequest({
    required this.id,
    required this.status,
    required this.description,
    required this.location,
    required this.preferredSchedule,
    required this.noArtisanReason,
    required this.serviceName,
    required this.quotation,
    required this.inspection,
    required this.completion,
  });

  final String id;
  final String status;
  final String description;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? preferredSchedule;
  final String? noArtisanReason;
  final String? serviceName;
  final Map<String, dynamic>? quotation;
  final Map<String, dynamic>? inspection;
  final Map<String, dynamic>? completion;

  factory TrackingRequest.fromJson(Map<String, dynamic> json) => TrackingRequest(
        id: json['id']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        location: json['location'] is Map ? _map(json['location']) : null,
        preferredSchedule:
            json['preferred_schedule'] is Map ? _map(json['preferred_schedule']) : null,
        noArtisanReason: json['no_artisan_reason']?.toString(),
        serviceName: json['service'] is Map ? _map(json['service'])['name']?.toString() : null,
        quotation: json['quotation'] is Map ? _map(json['quotation']) : null,
        inspection: json['inspection'] is Map ? _map(json['inspection']) : null,
        completion: json['completion'] is Map ? _map(json['completion']) : null,
      );

  String get locationLabel => location?['label']?.toString() ?? 'Location not provided';
  String get scheduleLabel {
    final date = preferredSchedule?['date']?.toString();
    final window = preferredSchedule?['window']?.toString();
    return [date, window].where((value) => value != null && value.isNotEmpty).join(' · ');
  }
}

class TrackingArtisan {
  const TrackingArtisan({
    required this.id,
    required this.userId,
    required this.name,
    required this.title,
    required this.experienceYears,
    required this.rating,
    required this.reviewCount,
    required this.hasPhoto,
  });

  final String id;
  final String userId;
  final String name;
  final String? title;
  final int experienceYears;
  final double rating;
  final int reviewCount;
  final bool hasPhoto;

  factory TrackingArtisan.fromJson(Map<String, dynamic> json) => TrackingArtisan(
        id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Your artisan',
        title: json['professional_title']?.toString(),
        experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
        rating: (json['rating_average'] as num?)?.toDouble() ?? 0,
        reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
        hasPhoto: json['has_photo'] == true,
      );
}

class PendingArtisanResponse {
  const PendingArtisanResponse({required this.expiresAt, required this.isExpired});
  final DateTime? expiresAt;
  final bool isExpired;
  factory PendingArtisanResponse.fromJson(Map<String, dynamic> json) => PendingArtisanResponse(
        expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
        isExpired: json['is_expired'] == true,
      );
}

class TrackingAction {
  const TrackingAction({required this.key, required this.label});
  final String key;
  final String label;
  factory TrackingAction.fromJson(Map<String, dynamic> json) => TrackingAction(
        key: json['key']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
      );
}

class TrackingPermissions {
  const TrackingPermissions({
    required this.canSelectArtisan,
    required this.canChangeArtisan,
    required this.canRetryMatching,
    required this.canEditRequest,
    required this.canCancelRequest,
    required this.canScheduleInspection,
    required this.canAcceptQuotation,
    required this.canConfirmCompletion,
  });

  final bool canSelectArtisan, canChangeArtisan, canRetryMatching, canEditRequest,
      canCancelRequest, canScheduleInspection, canAcceptQuotation, canConfirmCompletion;

  factory TrackingPermissions.fromJson(Map<String, dynamic> json) => TrackingPermissions(
        canSelectArtisan: json['can_select_artisan'] == true,
        canChangeArtisan: json['can_change_artisan'] == true,
        canRetryMatching: json['can_retry_matching'] == true,
        canEditRequest: json['can_edit_request'] == true,
        canCancelRequest: json['can_cancel_request'] == true,
        canScheduleInspection: json['can_schedule_inspection'] == true,
        canAcceptQuotation: json['can_accept_quotation'] == true,
        canConfirmCompletion: json['can_confirm_completion'] == true,
      );
}

class TrackingTimelineEntry {
  const TrackingTimelineEntry({required this.status, required this.label, required this.occurredAt, required this.isCurrent});
  final String? status;
  final String label;
  final DateTime? occurredAt;
  final bool isCurrent;
  factory TrackingTimelineEntry.fromJson(Map<String, dynamic> json) => TrackingTimelineEntry(
        status: json['status']?.toString(),
        label: json['label']?.toString() ?? 'Request updated',
        occurredAt: DateTime.tryParse(json['occurred_at']?.toString() ?? ''),
        isCurrent: json['is_current'] == true,
      );
}

Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic>
    ? value
    : value is Map
        ? Map<String, dynamic>.from(value)
        : const {};

List<dynamic> _list(dynamic value) => value is List ? value : const [];
