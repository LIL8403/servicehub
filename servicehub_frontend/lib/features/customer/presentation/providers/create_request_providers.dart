import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import '../../domain/models/service_request_draft.dart';

/// Holds the current wizard step (0-indexed: 0=describe, 1=location,
/// 2=schedule, 3=review) and the draft being built.
class CreateRequestState {
  const CreateRequestState({
    this.currentStep = 0,
    this.draft = const ServiceRequestDraft(),
  });

  final int currentStep;
  final ServiceRequestDraft draft;

  CreateRequestState copyWith({int? currentStep, ServiceRequestDraft? draft}) {
    return CreateRequestState(
      currentStep: currentStep ?? this.currentStep,
      draft: draft ?? this.draft,
    );
  }
}

class CreateRequestNotifier extends StateNotifier<CreateRequestState> {
  CreateRequestNotifier() : super(const CreateRequestState());

  void setCategory(String categoryId) {
    // Changing category invalidates any previously-picked service.
    state = state.copyWith(
      draft: ServiceRequestDraft(
        categoryId: categoryId,
        serviceId: null,
        description: state.draft.description,
        photoFiles: state.draft.photoFiles,
        urgency: state.draft.urgency,
        aiAssistEnabled: state.draft.aiAssistEnabled,
        locationLatitude: state.draft.locationLatitude,
        locationLongitude: state.draft.locationLongitude,
        formattedAddress: state.draft.formattedAddress,
        preferredDate: state.draft.preferredDate,
        preferredStartTime: state.draft.preferredStartTime,
        preferredEndTime: state.draft.preferredEndTime,
        isFlexible: state.draft.isFlexible,
        additionalNotes: state.draft.additionalNotes,
      ),
    );
  }

  void setService({required String serviceId, required String categoryId}) {
    state = state.copyWith(
      draft: state.draft.copyWith(serviceId: serviceId, categoryId: categoryId),
    );
  }

  void setDescription(String description) {
    state = state.copyWith(
      draft: state.draft.copyWith(description: description),
    );
  }

  void setUrgency(dynamic urgency) {
    state = state.copyWith(draft: state.draft.copyWith(urgency: urgency));
  }

  void setAiAssist(bool enabled) {
    state = state.copyWith(
      draft: state.draft.copyWith(aiAssistEnabled: enabled),
    );
  }

  void setPhotoFiles(List<XFile> files) {
    state = state.copyWith(draft: state.draft.copyWith(photoFiles: files));
  }

  void setLocation({
    required double latitude,
    required double longitude,
    required String formattedAddress,
  }) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        locationLatitude: latitude,
        locationLongitude: longitude,
        formattedAddress: formattedAddress,
      ),
    );
  }

  void clearLocation() {
    state = state.copyWith(
      draft: ServiceRequestDraft(
        categoryId: state.draft.categoryId,
        description: state.draft.description,
        photoFiles: state.draft.photoFiles,
        urgency: state.draft.urgency,
        aiAssistEnabled: state.draft.aiAssistEnabled,
        // location fields intentionally omitted (null)
        preferredDate: state.draft.preferredDate,
        preferredStartTime: state.draft.preferredStartTime,
        preferredEndTime: state.draft.preferredEndTime,
        isFlexible: state.draft.isFlexible,
        additionalNotes: state.draft.additionalNotes,
      ),
    );
  }

  /// Stores the typed address without coordinates. Used when the
  /// customer hasn't geocoded or picked a suggestion yet — the
  /// backend will geocode on submit if `location` is absent.
  void setAddressOnly(String address) {
    state = state.copyWith(
      draft: ServiceRequestDraft(
        categoryId: state.draft.categoryId,
        description: state.draft.description,
        photoFiles: state.draft.photoFiles,
        urgency: state.draft.urgency,
        aiAssistEnabled: state.draft.aiAssistEnabled,
        // Coordinates intentionally omitted (null).
        formattedAddress: address,
        preferredDate: state.draft.preferredDate,
        preferredStartTime: state.draft.preferredStartTime,
        preferredEndTime: state.draft.preferredEndTime,
        isFlexible: state.draft.isFlexible,
        additionalNotes: state.draft.additionalNotes,
      ),
    );
  }

  void setSchedule({
    DateTime? preferredDate,
    String? preferredStartTime,
    String? preferredEndTime,
    bool? isFlexible,
  }) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        preferredDate: preferredDate,
        preferredStartTime: preferredStartTime,
        preferredEndTime: preferredEndTime,
        isFlexible: isFlexible,
      ),
    );
  }

  void setAdditionalNotes(String notes) {
    state = state.copyWith(draft: state.draft.copyWith(additionalNotes: notes));
  }

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 3) {
      state = state.copyWith(currentStep: step);
    }
  }

  void reset() {
    state = const CreateRequestState();
  }
}

final createRequestProvider =
    StateNotifierProvider.autoDispose<
      CreateRequestNotifier,
      CreateRequestState
    >((ref) => CreateRequestNotifier());
