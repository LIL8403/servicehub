import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/artisan_earnings_repository.dart';
import '../../domain/models/earnings_summary.dart';
import '../../domain/models/payout_record.dart';

final artisanEarningsRepositoryProvider = Provider<ArtisanEarningsRepository>((
  ref,
) {
  return ArtisanEarningsRepository(apiService: ref.watch(apiServiceProvider));
});

final earningsSummaryProvider = FutureProvider.autoDispose<EarningsSummary>((
  ref,
) {
  return ref.watch(artisanEarningsRepositoryProvider).fetchSummary();
});

/// Payout history with pagination. The notifier holds the accumulated
/// list so "load more" appends without losing scroll position.
class PayoutHistoryState {
  const PayoutHistoryState({
    this.payouts = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<PayoutRecord> payouts;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  PayoutHistoryState copyWith({
    List<PayoutRecord>? payouts,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return PayoutHistoryState(
      payouts: payouts ?? this.payouts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PayoutHistoryNotifier extends StateNotifier<PayoutHistoryState> {
  PayoutHistoryNotifier(this._ref) : super(const PayoutHistoryState()) {
    _loadFirstPage();
  }

  final Ref _ref;
  int _page = 1;

  Future<void> _loadFirstPage() async {
    _page = 1;
    try {
      final result = await _ref
          .read(artisanEarningsRepositoryProvider)
          .fetchPayouts(page: 1);
      if (!mounted) return;
      state = PayoutHistoryState(
        payouts: result.payouts,
        hasMore: result.hasMore,
      );
    } catch (e) {
      if (!mounted) return;
      state = PayoutHistoryState(error: e.toString(), hasMore: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final next = _page + 1;
      final result = await _ref
          .read(artisanEarningsRepositoryProvider)
          .fetchPayouts(page: next);
      if (!mounted) return;
      _page = next;
      state = state.copyWith(
        payouts: [...state.payouts, ...result.payouts],
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> refresh() => _loadFirstPage();
}

final payoutHistoryProvider =
    StateNotifierProvider.autoDispose<
      PayoutHistoryNotifier,
      PayoutHistoryState
    >((ref) => PayoutHistoryNotifier(ref));
