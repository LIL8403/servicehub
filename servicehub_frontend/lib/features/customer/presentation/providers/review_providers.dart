import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ReviewRepository(apiService: api);
});

class ReviewSubmitState {
  const ReviewSubmitState({
    this.isSubmitting = false,
    this.errorMessage,
    this.submitted,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final SubmittedReview? submitted;

  ReviewSubmitState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    SubmittedReview? submitted,
    bool clearErrors = false,
  }) {
    return ReviewSubmitState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      submitted: submitted ?? this.submitted,
    );
  }
}

class ReviewSubmitNotifier extends StateNotifier<ReviewSubmitState> {
  ReviewSubmitNotifier(this._ref) : super(const ReviewSubmitState());

  final Ref _ref;

  Future<bool> submit({
    required String requestId,
    required int rating,
    String? comment,
  }) async {
    state = state.copyWith(isSubmitting: true, clearErrors: true);

    try {
      final result = await _ref.read(reviewRepositoryProvider).submit(
            requestId: requestId,
            rating: rating,
            comment: comment,
          );
      if (!mounted) return true;
      state = state.copyWith(isSubmitting: false, submitted: result);
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.firstErrorMessage,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not submit the review.',
      );
      return false;
    }
  }

  void reset() => state = const ReviewSubmitState();
}

final reviewSubmitProvider =
    StateNotifierProvider.autoDispose<ReviewSubmitNotifier, ReviewSubmitState>(
  (ref) => ReviewSubmitNotifier(ref),
);