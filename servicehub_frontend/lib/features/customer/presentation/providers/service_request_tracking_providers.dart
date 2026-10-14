import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/service_request_tracking_repository.dart';
import '../../domain/models/service_request_tracking.dart';

final serviceRequestTrackingRepositoryProvider =
    Provider<ServiceRequestTrackingRepository>((ref) {
      return ServiceRequestTrackingRepository(
        apiService: ref.watch(apiServiceProvider),
      );
    });

final serviceRequestTrackingProvider = StateNotifierProvider.autoDispose
    .family<
      ServiceRequestTrackingViewModel,
      AsyncValue<ServiceRequestTracking>,
      String
    >((ref, requestId) {
      return ServiceRequestTrackingViewModel(ref, requestId)..load();
    });

class ServiceRequestTrackingViewModel
    extends StateNotifier<AsyncValue<ServiceRequestTracking>> {
  ServiceRequestTrackingViewModel(this._ref, this.requestId)
    : super(const AsyncLoading());
  final Ref _ref;
  final String requestId;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await _ref
            .read(serviceRequestTrackingRepositoryProvider)
            .fetch(requestId),
      );
    } on ApiException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    } catch (error, stackTrace) {
      state = AsyncError(
        ApiException(message: 'Unable to load this request.'),
        stackTrace,
      );
    }
  }

  Future<bool> retryMatching() => _run(
    () => _ref
        .read(serviceRequestTrackingRepositoryProvider)
        .retryMatching(requestId),
  );
  Future<bool> changeArtisan() => _run(
    () => _ref
        .read(serviceRequestTrackingRepositoryProvider)
        .changeArtisan(requestId),
  );
  Future<bool> confirmCompletion() => _run(
    () => _ref
        .read(serviceRequestTrackingRepositoryProvider)
        .confirmCompletion(requestId),
  );
  Future<bool> cancel(String reason) => _run(
    () => _ref
        .read(serviceRequestTrackingRepositoryProvider)
        .cancel(requestId, reason),
  );

  Future<bool> _run(Future<void> Function() action) async {
    try {
      await action();
      await load();
      return true;
    } on ApiException catch (e) {
      // TEMPORARY — remove after diagnosing.
      // ignore: avoid_print
      print(
        '=== CANCEL FAILED === status=${e.statusCode} message=${e.firstErrorMessage} body=${e.body}',
      );
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('=== CANCEL FAILED (non-Api) === $e');
      return false;
    }
  }
}
