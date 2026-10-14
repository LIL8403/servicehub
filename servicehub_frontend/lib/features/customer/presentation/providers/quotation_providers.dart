import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/quotation_repository.dart';

final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return QuotationRepository(apiService: api);
});

/// Tracks the in-flight state of an accept/reject quotation action.
class QuotationActionState {
  const QuotationActionState({
    this.isSubmitting = false,
    this.errorMessage,
    this.lastAction,
  });

  final bool isSubmitting;
  final String? errorMessage;

  /// 'accept' or 'reject' — the last action attempted.
  final String? lastAction;

  QuotationActionState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    String? lastAction,
    bool clearErrors = false,
  }) {
    return QuotationActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      lastAction: lastAction ?? this.lastAction,
    );
  }
}

class QuotationActionNotifier extends StateNotifier<QuotationActionState> {
  QuotationActionNotifier(this._ref) : super(const QuotationActionState());

  final Ref _ref;

  /// Returns true on success. Callers should invalidate the request
  /// details provider on success to force a re-fetch.
  Future<bool> accept(String requestId) async {
    state = state.copyWith(
      isSubmitting: true,
      clearErrors: true,
      lastAction: 'accept',
    );

    try {
      await _ref.read(quotationRepositoryProvider).accept(requestId);
      if (!mounted) return true;
      state = state.copyWith(isSubmitting: false);
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
        errorMessage: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  Future<bool> reject(String requestId, {String? reason}) async {
    state = state.copyWith(
      isSubmitting: true,
      clearErrors: true,
      lastAction: 'reject',
    );

    try {
      await _ref
          .read(quotationRepositoryProvider)
          .reject(requestId, reason: reason);
      if (!mounted) return true;
      state = state.copyWith(isSubmitting: false);
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
        errorMessage: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  void reset() {
    state = const QuotationActionState();
  }
}

final quotationActionProvider = StateNotifierProvider.autoDispose<
    QuotationActionNotifier, QuotationActionState>(
  (ref) => QuotationActionNotifier(ref),
);