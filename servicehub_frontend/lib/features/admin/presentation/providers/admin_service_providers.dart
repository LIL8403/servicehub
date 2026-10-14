import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/admin_service_repository.dart';

final adminServiceRepositoryProvider =
    Provider<AdminServiceRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AdminServiceRepository(apiService: api);
});

/// All services, sorted by name.
final adminServicesProvider =
    FutureProvider.autoDispose<List<AdminService>>((ref) {
  final repo = ref.watch(adminServiceRepositoryProvider);
  return repo.fetchAll();
});

class AdminServiceActionState {
  const AdminServiceActionState({
    this.inFlight = false,
    this.errorMessage,
  });

  final bool inFlight;
  final String? errorMessage;

  AdminServiceActionState copyWith({
    bool? inFlight,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminServiceActionState(
      inFlight: inFlight ?? this.inFlight,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AdminServiceActionNotifier
    extends StateNotifier<AdminServiceActionState> {
  AdminServiceActionNotifier(this._ref)
      : super(const AdminServiceActionState());

  final Ref _ref;

  Future<bool> create({
    required String categoryId,
    required String name,
    required String? description,
    required bool isActive,
  }) async {
    state = state.copyWith(inFlight: true, clearError: true);
    try {
      await _ref.read(adminServiceRepositoryProvider).create(
            categoryId: categoryId,
            name: name,
            description: description,
            isActive: isActive,
          );
      if (!mounted) return true;
      state = state.copyWith(inFlight: false);
      _ref.invalidate(adminServicesProvider);
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

  Future<bool> update({
    required String id,
    required String categoryId,
    required String name,
    required String? description,
    required bool isActive,
  }) async {
    state = state.copyWith(inFlight: true, clearError: true);
    try {
      await _ref.read(adminServiceRepositoryProvider).update(
            id: id,
            categoryId: categoryId,
            name: name,
            description: description,
            isActive: isActive,
          );
      if (!mounted) return true;
      state = state.copyWith(inFlight: false);
      _ref.invalidate(adminServicesProvider);
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

final adminServiceActionProvider = StateNotifierProvider.autoDispose<
    AdminServiceActionNotifier, AdminServiceActionState>(
  (ref) => AdminServiceActionNotifier(ref),
);