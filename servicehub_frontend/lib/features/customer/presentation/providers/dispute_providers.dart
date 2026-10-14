import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/dispute_repository.dart';

final disputeRepositoryProvider = Provider<DisputeRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return DisputeRepository(apiService: api);
});

class DisputeSubmitState {
  const DisputeSubmitState({
    this.isSubmitting = false,
    this.errorMessage,
    this.opened,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final DisputeHandle? opened;

  DisputeSubmitState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    DisputeHandle? opened,
    bool clearErrors = false,
  }) {
    return DisputeSubmitState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      opened: opened ?? this.opened,
    );
  }
}

class DisputeSubmitNotifier extends StateNotifier<DisputeSubmitState> {
  DisputeSubmitNotifier(this._ref) : super(const DisputeSubmitState());

  final Ref _ref;

  /// Opens a dispute. Uploads any evidence files first, then submits
  /// the dispute with the returned references.
  Future<bool> open({
    required String requestId,
    required String reason,
    required String description,
    String? urgency,
    List<File> evidenceFiles = const [],
  }) async {
    state = state.copyWith(isSubmitting: true, clearErrors: true);

    try {
      List<EvidenceReference> references = const [];
      if (evidenceFiles.isNotEmpty) {
        references = await _ref
            .read(disputeRepositoryProvider)
            .uploadEvidence(evidenceFiles);
      }

      final result = await _ref.read(disputeRepositoryProvider).open(
            requestId: requestId,
            reason: reason,
            description: description,
            urgency: urgency,
            evidence: references,
          );
      if (!mounted) return true;
      state = state.copyWith(isSubmitting: false, opened: result);
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
        errorMessage: 'Could not open the dispute.',
      );
      return false;
    }
  }

  void reset() => state = const DisputeSubmitState();
}

final disputeSubmitProvider = StateNotifierProvider.autoDispose<
    DisputeSubmitNotifier, DisputeSubmitState>(
  (ref) => DisputeSubmitNotifier(ref),
);