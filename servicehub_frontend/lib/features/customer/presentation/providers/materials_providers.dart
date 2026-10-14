import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'request_tracking_providers.dart';

/// State for the "approve materials" action.
class MaterialsActionState {
  const MaterialsActionState({
    this.isSubmitting = false,
    this.errorMessage,
  });

  final bool isSubmitting;
  final String? errorMessage;

  MaterialsActionState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearErrors = false,
  }) {
    return MaterialsActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class MaterialsActionNotifier extends StateNotifier<MaterialsActionState> {
  MaterialsActionNotifier(this._ref) : super(const MaterialsActionState());

  final Ref _ref;

  /// Approves the currently proposed materials for [requestId].
  ///
  /// The backend requires the exact `estimated_total` sum, so we pass
  /// it as computed by the tracking provider. Any mismatch (the artisan
  /// silently updated the proposal) returns a validation error.
  Future<bool> approve({
    required String requestId,
    required double approvedTotal,
  }) async {
    state = state.copyWith(isSubmitting: true, clearErrors: true);

    try {
      final response = await _ref
          .read(apiServiceProvider)
          .authenticatedPost(
            '/customer/service-requests/$requestId/materials/approve',
            body: {'approved_total': approvedTotal},
          );

      // The endpoint returns the updated service request; we invalidate
      // the tracking provider so the view re-reads from the backend.
      jsonDecode(response.body);

      if (!mounted) return true;
      state = state.copyWith(isSubmitting: false);
      _ref.invalidate(serviceRequestDetailsProvider(requestId));
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
        errorMessage: 'Could not approve materials. Please try again.',
      );
      return false;
    }
  }

  void reset() => state = const MaterialsActionState();
}

final materialsActionProvider = StateNotifierProvider.autoDispose<
    MaterialsActionNotifier, MaterialsActionState>(
  (ref) => MaterialsActionNotifier(ref),
);