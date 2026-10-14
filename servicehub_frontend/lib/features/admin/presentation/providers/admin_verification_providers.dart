import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/admin_verification_repository.dart';

final adminVerificationRepositoryProvider =
    Provider<AdminVerificationRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AdminVerificationRepository(apiService: api);
});

/// The list of pending artisan applications. Auto-disposed so it
/// refreshes on every visit.
final pendingArtisansProvider =
    FutureProvider.autoDispose<List<PendingArtisan>>((ref) {
  final repo = ref.watch(adminVerificationRepositoryProvider);
  return repo.fetchPending();
});

/// The currently selected artisan in the queue.
///
/// Returns null if the queue is empty.
final selectedArtisanProvider =
    StateProvider.autoDispose<PendingArtisan?>((ref) => null);

/// In-flight action state for approve/reject.
class AdminVerificationActionState {
  const AdminVerificationActionState({
    this.inFlightId,
    this.errorMessage,
  });

  final String? inFlightId;
  final String? errorMessage;

  AdminVerificationActionState copyWith({
    String? inFlightId,
    String? errorMessage,
    bool clearInFlight = false,
    bool clearError = false,
  }) {
    return AdminVerificationActionState(
      inFlightId: clearInFlight ? null : (inFlightId ?? this.inFlightId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AdminVerificationActionNotifier
    extends StateNotifier<AdminVerificationActionState> {
  AdminVerificationActionNotifier(this._ref)
      : super(const AdminVerificationActionState());

  final Ref _ref;

  Future<bool> approve(String artisanId) async {
    state = state.copyWith(inFlightId: artisanId, clearError: true);
    try {
      await _ref
          .read(adminVerificationRepositoryProvider)
          .approve(artisanId);
      if (!mounted) return true;
      state = state.copyWith(clearInFlight: true);
      _ref.invalidate(pendingArtisansProvider);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        clearInFlight: true,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> reject(String artisanId, String reason) async {
    state = state.copyWith(inFlightId: artisanId, clearError: true);
    try {
      await _ref
          .read(adminVerificationRepositoryProvider)
          .reject(artisanId, reason);
      if (!mounted) return true;
      state = state.copyWith(clearInFlight: true);
      _ref.invalidate(pendingArtisansProvider);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        clearInFlight: true,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final adminVerificationActionProvider = StateNotifierProvider.autoDispose<
    AdminVerificationActionNotifier, AdminVerificationActionState>(
  (ref) => AdminVerificationActionNotifier(ref),
);