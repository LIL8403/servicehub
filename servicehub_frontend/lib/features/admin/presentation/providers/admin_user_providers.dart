import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/admin_user_repository.dart';

final adminUserRepositoryProvider = Provider<AdminUserRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AdminUserRepository(apiService: api);
});

/// The current filter set for the users list. Mutated by the page.
final adminUsersFilterProvider =
    StateProvider.autoDispose<AdminUsersFilter>(
  (ref) => const AdminUsersFilter(),
);

/// The current page of users, keyed by the filter.
final adminUsersPageProvider =
    FutureProvider.autoDispose<AdminUsersResponse>((ref) {
  final repo = ref.watch(adminUserRepositoryProvider);
  final filter = ref.watch(adminUsersFilterProvider);
  return repo.fetch(filter);
});

/// In-flight state for the status change action.
class AdminUserActionState {
  const AdminUserActionState({
    this.inFlight = false,
    this.errorMessage,
  });

  final bool inFlight;
  final String? errorMessage;

  AdminUserActionState copyWith({
    bool? inFlight,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminUserActionState(
      inFlight: inFlight ?? this.inFlight,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AdminUserActionNotifier
    extends StateNotifier<AdminUserActionState> {
  AdminUserActionNotifier(this._ref)
      : super(const AdminUserActionState());

  final Ref _ref;

  Future<bool> updateStatus({
    required String userId,
    required String status,
    required String reason,
  }) async {
    state = state.copyWith(inFlight: true, clearError: true);
    try {
      await _ref.read(adminUserRepositoryProvider).updateStatus(
            userId: userId,
            status: status,
            reason: reason,
          );
      if (!mounted) return true;
      state = state.copyWith(inFlight: false);
      _ref.invalidate(adminUsersPageProvider);
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

final adminUserActionProvider = StateNotifierProvider.autoDispose<
    AdminUserActionNotifier, AdminUserActionState>(
  (ref) => AdminUserActionNotifier(ref),
);