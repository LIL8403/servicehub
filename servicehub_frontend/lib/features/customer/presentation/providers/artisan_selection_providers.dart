import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/artisan_selection_repository.dart';
import '../../domain/models/eligible_artisans_response.dart';

final artisanSelectionRepositoryProvider = Provider<ArtisanSelectionRepository>(
  (ref) {
    final api = ref.watch(apiServiceProvider);
    return ArtisanSelectionRepository(apiService: api);
  },
);

/// Fetches eligible artisans for a given service request.
/// The family arg is the requestId.
final eligibleArtisansProvider =
    FutureProvider.family<EligibleArtisansResponse, String>((
      ref,
      requestId,
    ) async {
      final repo = ref.watch(artisanSelectionRepositoryProvider);
      return repo.fetchEligibleArtisans(requestId);
    });

/// Manages the "select artisan" submission state.
class SelectionState {
  const SelectionState({
    this.isSubmitting = false,
    this.errorMessage,
    this.selectedArtisanId,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final String? selectedArtisanId;

  SelectionState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    String? selectedArtisanId,
    bool clearErrors = false,
  }) {
    return SelectionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      selectedArtisanId: selectedArtisanId ?? this.selectedArtisanId,
    );
  }
}

class SelectionNotifier extends StateNotifier<SelectionState> {
  SelectionNotifier(this._ref) : super(const SelectionState());

  final Ref _ref;

  Future<bool> selectArtisan({
    required String requestId,
    required String artisanId,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearErrors: true,
      selectedArtisanId: artisanId,
    );

    try {
      await _ref
          .read(artisanSelectionRepositoryProvider)
          .selectArtisan(requestId: requestId, artisanId: artisanId);

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
    state = const SelectionState();
  }
}

final selectionProvider =
    StateNotifierProvider.autoDispose<SelectionNotifier, SelectionState>(
      (ref) => SelectionNotifier(ref),
    );

/// Fetches the profile photo bytes for a given user ID.
/// Uses ApiService so the Bearer token is automatically attached.
/// Caches the bytes for the app session.
final artisanPhotoProvider = FutureProvider.family<Uint8List?, String>((
  ref,
  userId,
) async {
  if (userId.isEmpty) return null;

  final api = ref.watch(apiServiceProvider);

  try {
    final response = await api.authenticatedGet('/users/$userId/photo');

    if (response.statusCode == 200) {
      return Uint8List.fromList(response.bodyBytes);
    }
    return null;
  } catch (_) {
    return null;
  }
});
