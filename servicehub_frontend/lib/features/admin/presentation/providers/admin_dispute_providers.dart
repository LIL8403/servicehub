import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/admin_dispute_repository.dart';

final adminDisputeRepositoryProvider =
    Provider<AdminDisputeRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AdminDisputeRepository(apiService: api);
});

/// The status filter applied to the queue.
final disputeStatusFilterProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// The list of disputes, optionally filtered by status.
final disputesListProvider =
    FutureProvider.autoDispose<List<DisputeSummary>>((ref) {
  final repo = ref.watch(adminDisputeRepositoryProvider);
  final status = ref.watch(disputeStatusFilterProvider);
  return repo.fetchAll(status: status);
});

/// The currently selected dispute id.
final selectedDisputeIdProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// The full detail of the selected dispute.
final disputeDetailProvider = FutureProvider.autoDispose
    .family<DisputeDetailResponse, String>((ref, id) {
  final repo = ref.watch(adminDisputeRepositoryProvider);
  return repo.fetchDetail(id);
});

/// In-flight state for dispute actions.
class DisputeActionState {
  const DisputeActionState({
    this.inFlight = false,
    this.errorMessage,
  });

  final bool inFlight;
  final String? errorMessage;

  DisputeActionState copyWith({
    bool? inFlight,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DisputeActionState(
      inFlight: inFlight ?? this.inFlight,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DisputeActionNotifier extends StateNotifier<DisputeActionState> {
  DisputeActionNotifier(this._ref) : super(const DisputeActionState());

  final Ref _ref;

  Future<bool> run(
    String disputeId,
    Future<void> Function(AdminDisputeRepository repo) action,
  ) async {
    state = state.copyWith(inFlight: true, clearError: true);
    try {
      await action(_ref.read(adminDisputeRepositoryProvider));
      if (!mounted) return true;
      state = state.copyWith(inFlight: false);
      _ref.invalidate(disputeDetailProvider(disputeId));
      _ref.invalidate(disputesListProvider);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        inFlight: false,
        errorMessage: _cleanError(e),
      );
      return false;
    }
  }

  String _cleanError(Object e) {
    final str = e.toString();
    final match = RegExp(r'ApiException\(\d+\):\s*(.*)').firstMatch(str);
    return match?.group(1) ?? str;
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final disputeActionProvider = StateNotifierProvider.autoDispose<
    DisputeActionNotifier, DisputeActionState>(
  (ref) => DisputeActionNotifier(ref),
);