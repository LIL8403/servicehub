import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/artisan_profile_repository.dart';

final artisanProfileRepositoryProvider =
    Provider<ArtisanProfileRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ArtisanProfileRepository(apiService: api);
});

final artisanProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  final repo = ref.watch(artisanProfileRepositoryProvider);
  return repo.fetchProfile();
});

class ArtisanProfileActionState {
  const ArtisanProfileActionState({
    this.isSaving = false,
    this.errorMessage,
  });

  final bool isSaving;
  final String? errorMessage;

  ArtisanProfileActionState copyWith({
    bool? isSaving,
    String? errorMessage,
    bool clearErrors = false,
  }) {
    return ArtisanProfileActionState(
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ArtisanProfileActionNotifier
    extends StateNotifier<ArtisanProfileActionState> {
  ArtisanProfileActionNotifier(this._ref)
      : super(const ArtisanProfileActionState());

  final Ref _ref;

  Future<bool> save(Map<String, dynamic> payload) async {
    state = state.copyWith(isSaving: true, clearErrors: true);

    try {
      await _ref.read(artisanProfileRepositoryProvider).updateProfile(payload);
      if (!mounted) return true;
      state = state.copyWith(isSaving: false);
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.firstErrorMessage,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Could not save your profile.',
      );
      return false;
    }
  }

  void reset() => state = const ArtisanProfileActionState();
}

final artisanProfileActionProvider = StateNotifierProvider.autoDispose<
    ArtisanProfileActionNotifier, ArtisanProfileActionState>(
  (ref) => ArtisanProfileActionNotifier(ref),
);