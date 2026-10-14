import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';

/// The response shape for a submitted review, matching the backend's
/// `{review: {...}}` payload.
class SubmittedReview {
  const SubmittedReview({
    required this.id,
    required this.rating,
    this.comment,
  });

  final String id;
  final int rating;
  final String? comment;

  factory SubmittedReview.fromJson(Map<String, dynamic> json) {
    return SubmittedReview(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString(),
    );
  }
}

class ReviewRepository {
  ReviewRepository({required this.apiService});

  final ApiService apiService;

  /// Submits a review. The backend accepts only `rating` and `comment`.
  /// Any tags or photos collected in the UI are not sent — they would
  /// be silently dropped. When the backend supports them, add them
  /// here as additional body fields.
  Future<SubmittedReview> submit({
    required String requestId,
    required int rating,
    String? comment,
  }) async {
    if (requestId.isEmpty) {
      throw const ApiException(
        message: 'A request ID is required to submit a review.',
        statusCode: 400,
      );
    }
    if (rating < 1 || rating > 5) {
      throw const ApiException(
        message: 'Rating must be between 1 and 5.',
        statusCode: 400,
      );
    }

    try {
      final response = await apiService.authenticatedPost(
        '/customer/service-requests/$requestId/reviews',
        body: {
          'rating': rating,
          if (comment != null && comment.trim().isNotEmpty)
            'comment': comment.trim(),
        },
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final review = json['review'] as Map<String, dynamic>?;

      if (review == null) {
        throw const ApiException(
          message: 'The server returned an unexpected response format.',
          statusCode: 500,
        );
      }

      return SubmittedReview.fromJson(review);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to submit review: $e');
    }
  }
}