import 'package:flutter/foundation.dart';

/// Advisory output from
/// `POST /api/ai/service-requests/{id}/quotation/analyze`.
///
/// Mirrors the backend envelope:
///   {
///     "available": bool,
///     "reason"?: "unavailable"|"no_quotation",
///     "result"?: {
///       is_flagged: bool,
///       explanation: string,
///       confidence_score: int
///     }
///   }
///
/// This is advisory ONLY. It never accepts, rejects, or alters a quotation.
@immutable
class QuotationAnalysis {
  const QuotationAnalysis({
    required this.available,
    this.reason,
    this.isFlagged = false,
    this.explanation,
    this.confidenceScore = 0,
  });

  final bool available;
  final String? reason;
  final bool isFlagged;
  final String? explanation;
  final int confidenceScore;

  bool get isUnavailable => reason == 'unavailable';

  factory QuotationAnalysis.fromEnvelope(Map<String, dynamic> json) {
    final available = json['available'] == true;
    if (!available) {
      return QuotationAnalysis(
        available: false,
        reason: json['reason']?.toString(),
      );
    }

    final result = json['result'];
    if (result is! Map<String, dynamic>) {
      return const QuotationAnalysis(
        available: false,
        reason: 'unavailable',
      );
    }

    return QuotationAnalysis(
      available: true,
      isFlagged: result['is_flagged'] == true,
      explanation: result['explanation']?.toString(),
      confidenceScore: (result['confidence_score'] as num?)?.toInt() ?? 0,
    );
  }
}