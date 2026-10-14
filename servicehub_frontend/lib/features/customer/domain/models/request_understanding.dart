import 'package:flutter/foundation.dart';

import '../enums/urgency_level.dart';

/// Advisory output from `POST /api/ai/understand-draft`
/// (and `POST /api/ai/service-requests/{id}/understand`).
///
/// Mirrors the backend envelope:
///   {
///     "available": bool,
///     "reason"?: "unavailable"|"low_confidence"|"empty_description",
///     "provider"?: string,
///     "model"?: string,
///     "analyzed_at"?: string,
///     "result"?: {
///       problem_type: string,
///       urgency: "low"|"normal"|"high"|"emergency",
///       useful_context: string[],
///       missing_information: string[],
///       confidence_score: int
///     }
///   }
@immutable
class RequestUnderstanding {
  const RequestUnderstanding({
    required this.available,
    this.reason,
    this.problemType,
    this.urgency,
    this.usefulContext = const [],
    this.missingInformation = const [],
    this.confidenceScore = 0, this.rewrittenDescription,
  });

  final bool available;

  /// Set when [available] is false: `unavailable`, `low_confidence`,
  /// `empty_description`, or any future backend reason.
  final String? reason;

  final String? problemType;
  final UrgencyLevel? urgency;
  final List<String> usefulContext;
  final List<String> missingInformation;
  final String? rewrittenDescription;
  final int confidenceScore;

  bool get isLowConfidence => reason == 'low_confidence';
  bool get isUnavailable => reason == 'unavailable';

  factory RequestUnderstanding.fromEnvelope(Map<String, dynamic> json) {
    final available = json['available'] == true;
    final reason = json['reason']?.toString();

    if (!available) {
      return RequestUnderstanding(available: false, reason: reason);
    }

    final result = json['result'];
    if (result is! Map<String, dynamic>) {
      return const RequestUnderstanding(
        available: false,
        reason: 'unavailable',
      );
    }

    return RequestUnderstanding(
      available: true,
      problemType: result['problem_type']?.toString(),
      urgency: _parseUrgency(result['urgency']?.toString()),
      usefulContext: _stringList(result['useful_context']),
      missingInformation: _stringList(result['missing_information']),
      confidenceScore: (result['confidence_score'] as num?)?.toInt() ?? 0,
      rewrittenDescription: result['rewritten_description']?.toString(),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Object>()
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  /// Backend uses `normal`; the app enum uses `medium`.
  static UrgencyLevel? _parseUrgency(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return UrgencyLevel.low;
      case 'normal':
      case 'medium':
        return UrgencyLevel.medium;
      case 'high':
        return UrgencyLevel.high;
      case 'emergency':
        return UrgencyLevel.high; // emergency collapses to high in v1
      default:
        return null;
    }
  }
}