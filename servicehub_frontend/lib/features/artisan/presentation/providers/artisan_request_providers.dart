import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../customer/domain/models/service_request.dart';
import '../../data/repositories/artisan_request_repository.dart';
import '../../domain/models/artisan_request_summary.dart';

final artisanRequestRepositoryProvider = Provider<ArtisanRequestRepository>((
  ref,
) {
  final api = ref.watch(apiServiceProvider);
  return ArtisanRequestRepository(apiService: api);
});

/// All requests assigned to the current artisan. Auto-disposes so the
/// dashboard refreshes when the artisan navigates back to it.
final artisanRequestsProvider =
    FutureProvider.autoDispose<List<ArtisanRequestSummary>>((ref) {
      final repo = ref.watch(artisanRequestRepositoryProvider);
      return repo.listRequests();
    });

/// Full details for a single request. Family arg is the request id.
final artisanRequestDetailsProvider = FutureProvider.autoDispose
    .family<ServiceRequest, String>((ref, requestId) {
      final repo = ref.watch(artisanRequestRepositoryProvider);
      return repo.fetchRequestDetails(requestId);
    });

/// Tracks the state of an in-flight artisan action (accept, decline,
/// start, complete, submit quotation).
class ArtisanActionState {
  const ArtisanActionState({
    this.isSubmitting = false,
    this.errorMessage,
    this.lastAction,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final String? lastAction;

  ArtisanActionState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    String? lastAction,
    bool clearErrors = false,
  }) {
    return ArtisanActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      lastAction: lastAction ?? this.lastAction,
    );
  }
}

class ArtisanActionNotifier extends StateNotifier<ArtisanActionState> {
  ArtisanActionNotifier(this._ref) : super(const ArtisanActionState());

  final Ref _ref;

  Future<bool> approve(String requestId) =>
      _run('approve', (repo) => repo.approve(requestId));

  Future<bool> decline(String requestId, {String? reason}) =>
      _run('decline', (repo) => repo.decline(requestId, reason: reason));

  Future<bool> start(String requestId) =>
      _run('start', (repo) => repo.start(requestId));

  Future<bool> reportCompletion(String requestId, {String? notes}) => _run(
    'completion',
    (repo) => repo.reportCompletion(requestId, notes: notes),
  );

  Future<bool> submitQuotation({
    required String requestId,
    required double laborAmount,
    required String scope,
    required String validUntil,
    String? notes,
  }) => _run(
    'quotation',
    (repo) => repo.submitQuotation(
      requestId,
      laborAmount: laborAmount,
      scope: scope,
      validUntil: validUntil,
      notes: notes,
    ),
  );

  Future<bool> proposeMaterials({
    required String requestId,
    required List<Map<String, dynamic>> materials,
  }) => _run(
    'materials',
    (repo) => repo.proposeMaterials(requestId, materials: materials),
  );

  Future<bool> completeInspection({
    required String requestId,
    required String findings,
  }) => _run(
    'inspection',
    (repo) => repo.completeInspection(requestId, findings: findings),
  );

  Future<bool> _run(
    String action,
    Future<ServiceRequest> Function(ArtisanRequestRepository) execute,
  ) async {
    state = state.copyWith(
      isSubmitting: true,
      clearErrors: true,
      lastAction: action,
    );

    try {
      await execute(_ref.read(artisanRequestRepositoryProvider));
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
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  void reset() => state = const ArtisanActionState();
}

final artisanActionProvider =
    StateNotifierProvider.autoDispose<
      ArtisanActionNotifier,
      ArtisanActionState
    >((ref) => ArtisanActionNotifier(ref));

/// Fetches the raw bytes of a single image attachment on a request.
///
/// Keyed by `(requestId, imageId)`. The backend streams the file
/// through the authenticated endpoint so the token is attached by
/// `ApiService`.
final requestImageBytesProvider = FutureProvider.autoDispose
    .family<Uint8List?, ({String requestId, String imageId})>((ref, key) async {
      if (key.requestId.isEmpty || key.imageId.isEmpty) return null;

      final api = ref.watch(apiServiceProvider);
      try {
        final response = await api.authenticatedGet(
          '/artisan/service-requests/${key.requestId}/images/${key.imageId}',
        );
        if (response.statusCode == 200) {
          return Uint8List.fromList(response.bodyBytes);
        }
        return null;
      } catch (_) {
        return null;
      }
    });
