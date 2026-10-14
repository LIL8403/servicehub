import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/artisan_verification_repository.dart';

final artisanVerificationRepositoryProvider =
    Provider<ArtisanVerificationRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ArtisanVerificationRepository(apiService: api);
});

/// The current verification snapshot: state + document-type config.
final artisanVerificationProvider =
    FutureProvider.autoDispose<VerificationSnapshot>((ref) {
  final repo = ref.watch(artisanVerificationRepositoryProvider);
  return repo.fetch();
});

/// Tracks in-flight verification actions.
class VerificationActionState {
  const VerificationActionState({
    this.isSubmitting = false,
    this.errorMessage,
    this.lastAction,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final String? lastAction;

  VerificationActionState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    String? lastAction,
    bool clearErrors = false,
  }) {
    return VerificationActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      lastAction: lastAction ?? this.lastAction,
    );
  }
}

class VerificationActionNotifier
    extends StateNotifier<VerificationActionState> {
  VerificationActionNotifier(this._ref) : super(const VerificationActionState());

  final Ref _ref;

  Future<bool> saveIdentity({
    required String legalName,
    required String dateOfBirth,
    required String residentialAddress,
  }) =>
      _run('identity', () => _ref
          .read(artisanVerificationRepositoryProvider)
          .saveIdentity(
            legalName: legalName,
            dateOfBirth: dateOfBirth,
            residentialAddress: residentialAddress,
          ));

  Future<bool> uploadIdentityDocument({
    required String documentType,
    required String documentNumber,
    String? expiresAt,
    required File front,
    File? back,
  }) =>
      _run('identity-document', () => _ref
          .read(artisanVerificationRepositoryProvider)
          .uploadIdentityDocument(
            documentType: documentType,
            documentNumber: documentNumber,
            expiresAt: expiresAt,
            front: front,
            back: back,
          ));

  Future<bool> uploadSelfie(File selfie) => _run(
        'selfie',
        () => _ref
            .read(artisanVerificationRepositoryProvider)
            .uploadSelfie(selfie),
      );

  Future<bool> uploadSupportingDocument({
    required String documentType,
    String? label,
    required File document,
  }) =>
      _run('supporting-document', () => _ref
          .read(artisanVerificationRepositoryProvider)
          .uploadSupportingDocument(
            documentType: documentType,
            label: label,
            document: document,
          ));

  Future<bool> deleteSupportingDocument(String documentId) => _run(
        'delete-document',
        () => _ref
            .read(artisanVerificationRepositoryProvider)
            .deleteSupportingDocument(documentId),
      );

  Future<bool> submit() => _run(
        'submit',
        () => _ref.read(artisanVerificationRepositoryProvider).submit(),
      );

  Future<bool> _run(
    String action,
    Future<VerificationSnapshot> Function() execute,
  ) async {
    state = state.copyWith(
      isSubmitting: true,
      clearErrors: true,
      lastAction: action,
    );

    try {
      await execute();
      if (!mounted) return true;
      state = state.copyWith(isSubmitting: false);
      _ref.invalidate(artisanVerificationProvider);
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
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  void reset() => state = const VerificationActionState();
}

final verificationActionProvider = StateNotifierProvider.autoDispose<
    VerificationActionNotifier, VerificationActionState>(
  (ref) => VerificationActionNotifier(ref),
);