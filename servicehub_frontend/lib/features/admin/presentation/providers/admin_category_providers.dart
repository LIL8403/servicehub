import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/admin_category_repository.dart';

final adminCategoryRepositoryProvider =
    Provider<AdminCategoryRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AdminCategoryRepository(apiService: api);
});

/// All service categories, sorted by name.
final adminCategoriesProvider =
    FutureProvider.autoDispose<List<AdminCategory>>((ref) {
  final repo = ref.watch(adminCategoryRepositoryProvider);
  return repo.fetchAll();
});

/// In-flight state for create/update/delete actions.
class AdminCategoryActionState {
  const AdminCategoryActionState({
    this.inFlight = false,
    this.errorMessage,
  });

  final bool inFlight;
  final String? errorMessage;

  AdminCategoryActionState copyWith({
    bool? inFlight,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminCategoryActionState(
      inFlight: inFlight ?? this.inFlight,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AdminCategoryActionNotifier
    extends StateNotifier<AdminCategoryActionState> {
  AdminCategoryActionNotifier(this._ref)
      : super(const AdminCategoryActionState());

  final Ref _ref;

  Future<bool> create({
    required String name,
    required String? description,
    required bool isActive,
  }) async {
    state = state.copyWith(inFlight: true, clearError: true);
    try {
      await _ref.read(adminCategoryRepositoryProvider).create(
            name: name,
            description: description,
            isActive: isActive,
          );
      if (!mounted) return true;
      state = state.copyWith(inFlight: false);
      _ref.invalidate(adminCategoriesProvider);
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
    required String name,
    required String? description,
    required bool isActive,
  }) async {
    state = state.copyWith(inFlight: true, clearError: true);
    try {
      await _ref.read(adminCategoryRepositoryProvider).update(
            id: id,
            name: name,
            description: description,
            isActive: isActive,
          );
      if (!mounted) return true;
      state = state.copyWith(inFlight: false);
      _ref.invalidate(adminCategoriesProvider);
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

  Future<bool> delete(String id) async {
    state = state.copyWith(inFlight: true, clearError: true);
    try {
      await _ref.read(adminCategoryRepositoryProvider).delete(id);
      if (!mounted) return true;
      state = state.copyWith(inFlight: false);
      _ref.invalidate(adminCategoriesProvider);
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
    // Strip the ApiException prefix if present.
    final match = RegExp(r'ApiException\(\d+\):\s*(.*)').firstMatch(str);
    return match?.group(1) ?? str;
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final adminCategoryActionProvider = StateNotifierProvider.autoDispose<
    AdminCategoryActionNotifier, AdminCategoryActionState>(
  (ref) => AdminCategoryActionNotifier(ref),
);