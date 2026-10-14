import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/service_request_repository.dart';
import '../../domain/models/service_request_draft.dart';

class SubmitState {
  const SubmitState({
    this.isSubmitting = false,
    this.errorMessage,
    this.submittedId,
    this.submittedAiAssist,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final String? submittedId;
  final bool? submittedAiAssist;

  SubmitState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    String? submittedId,
    bool? submittedAiAssist,
    bool clearErrors = false,
  }) {
    return SubmitState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      submittedId: submittedId ?? this.submittedId,
      submittedAiAssist: submittedAiAssist ?? this.submittedAiAssist,
    );
  }
}

final serviceRequestRepositoryProvider = Provider<ServiceRequestRepository>((
  ref,
) {
  final api = ref.watch(apiServiceProvider);
  return ServiceRequestRepository(apiService: api);
});

class SubmitNotifier extends StateNotifier<SubmitState> {
  SubmitNotifier(this._ref) : super(const SubmitState());

  final Ref _ref;

  Future<bool> submit(ServiceRequestDraft draft) async {
    state = state.copyWith(isSubmitting: true, clearErrors: true);

    try {
      final serviceId = draft.serviceId;

      if (serviceId == null || serviceId.isEmpty) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Please pick a service before continuing.',
        );
        return false;
      }

      final result = await _ref
          .read(serviceRequestRepositoryProvider)
          .submit(draft: draft, serviceId: serviceId);

      state = state.copyWith(
        isSubmitting: false,
        submittedId: result.id,
        submittedAiAssist: result.aiAssistEnabled,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.firstErrorMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  void reset() {
    state = const SubmitState();
  }
}

final submitProvider =
    StateNotifierProvider.autoDispose<SubmitNotifier, SubmitState>(
      (ref) => SubmitNotifier(ref),
    );
