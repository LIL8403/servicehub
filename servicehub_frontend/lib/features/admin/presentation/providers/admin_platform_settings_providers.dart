import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/admin_platform_settings_repository.dart';

final adminPlatformSettingsRepositoryProvider =
    Provider<AdminPlatformSettingsRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AdminPlatformSettingsRepository(apiService: api);
});

final commissionSettingsProvider =
    FutureProvider.autoDispose<CommissionSettings>((ref) {
  final repo = ref.watch(adminPlatformSettingsRepositoryProvider);
  return repo.fetchCommission();
});

class CommissionActionState {
  const CommissionActionState({
    this.inFlight = false,
    this.errorMessage,
  });

  final bool inFlight;
  final String? errorMessage;

  CommissionActionState copyWith({
    bool? inFlight,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CommissionActionState(
      inFlight: inFlight ?? this.inFlight,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CommissionActionNotifier
    extends StateNotifier<CommissionActionState> {
  CommissionActionNotifier(this._ref)
      : super(const CommissionActionState());

  final Ref _ref;

  Future<bool> update({
    required double rate,
    required String reason,
  }) async {
    state = state.copyWith(inFlight: true, clearError: true);
    try {
      await _ref.read(adminPlatformSettingsRepositoryProvider).updateCommission(
            rate: rate,
            reason: reason,
          );
      if (!mounted) return true;
      state = state.copyWith(inFlight: false);
      _ref.invalidate(commissionSettingsProvider);
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

final commissionActionProvider = StateNotifierProvider.autoDispose<
    CommissionActionNotifier, CommissionActionState>(
  (ref) => CommissionActionNotifier(ref),
);