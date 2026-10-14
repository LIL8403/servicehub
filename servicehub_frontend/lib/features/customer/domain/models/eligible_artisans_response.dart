import 'artisan_summary.dart';

class EligibleArtisansResponse {
  const EligibleArtisansResponse({
    required this.artisans,
    required this.aiRecommendations,
    required this.request,
  });

  final List<ArtisanSummary> artisans;
  final List<AiRecommendation> aiRecommendations;
  final RequestSnapshot request;

  /// True when the backend has stored AI rankings for this request.
  bool get hasAiRecommendations =>
      request.aiRecommendationsAvailable && aiRecommendations.isNotEmpty;

  /// Returns the artisan matching the given id, or null.
  ArtisanSummary? artisanById(String id) {
    for (final a in artisans) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// The AI-ranked artisans, in order of match score descending,
  /// resolved to their full ArtisanSummary objects. Any ranking whose
  /// artisan_id does not match an artisan in the list is skipped.
  List<({ArtisanSummary artisan, AiRecommendation recommendation})>
      get rankedArtisans {
    final result =
        <({ArtisanSummary artisan, AiRecommendation recommendation})>[];
    for (final rec in aiRecommendations) {
      final a = artisanById(rec.artisanId);
      if (a != null) {
        result.add((artisan: a, recommendation: rec));
      }
    }
    return result;
  }

  /// The artisans not present in the AI recommendations list.
  List<ArtisanSummary> get otherArtisans {
    final rankedIds = aiRecommendations.map((r) => r.artisanId).toSet();
    return artisans.where((a) => !rankedIds.contains(a.id)).toList();
  }

  factory EligibleArtisansResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['artisans'] as List?) ?? [];
    final aiList = (json['ai_recommendations'] as List?) ?? [];
    final requestJson = (json['request'] as Map<String, dynamic>?) ?? {};

    return EligibleArtisansResponse(
      artisans: list
          .whereType<Map<String, dynamic>>()
          .map((a) => ArtisanSummary.fromJson(a))
          .toList(),
      aiRecommendations: aiList
          .whereType<Map<String, dynamic>>()
          .map((r) => AiRecommendation.fromJson(r))
          .toList(),
      request: RequestSnapshot.fromJson(requestJson),
    );
  }
}

class AiRecommendation {
  const AiRecommendation({
    required this.artisanId,
    required this.matchScore,
    required this.reason,
  });

  final String artisanId;
  final int matchScore;
  final String reason;

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      artisanId: json['artisan_id']?.toString() ?? '',
      matchScore: (json['match_score'] as num?)?.toInt() ?? 0,
      reason: json['reason']?.toString() ?? '',
    );
  }
}

class RequestSnapshot {
  const RequestSnapshot({
    required this.id,
    required this.serviceId,
    required this.status,
    required this.location,
    required this.preferredSchedule,
    required this.aiAssistEnabled,
    required this.aiRecommendationsAvailable,
    required this.noArtisanReason,
  });

  final String id;
  final String serviceId;
  final String status;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? preferredSchedule;
  final bool aiAssistEnabled;
  final bool aiRecommendationsAvailable;
  final String? noArtisanReason;

  factory RequestSnapshot.fromJson(Map<String, dynamic> json) {
    return RequestSnapshot(
      id: json['id']?.toString() ?? '',
      serviceId: json['service_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      location: json['location'] as Map<String, dynamic>?,
      preferredSchedule: json['preferred_schedule'] as Map<String, dynamic>?,
      aiAssistEnabled: json['ai_assist_enabled'] == true,
      aiRecommendationsAvailable:
          json['ai_recommendations_available'] == true,
      noArtisanReason: json['no_artisan_reason']?.toString(),
    );
  }
}