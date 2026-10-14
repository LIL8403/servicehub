import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/service_request_repository.dart';
import '../../domain/models/service_request.dart';

/// Provides the shared [ServiceRequestRepository] instance for the
/// tracking feature.
///
/// A parallel provider is defined in `submit_request_providers.dart`
/// for the wizard flow. Keeping them separate avoids a circular import
/// between the two provider files, and keeps each feature's dependency
/// graph explicit.
final requestTrackingRepositoryProvider = Provider<ServiceRequestRepository>(
  (ref) {
    final api = ref.watch(apiServiceProvider);
    return ServiceRequestRepository(apiService: api);
  },
);

/// Fetches the full details of a single service request by ID.
///
/// The family argument is the request's MongoDB `_id`. The provider
/// auto-disposes, so navigating away from the tracking screen and
/// back re-fetches fresh data — which is what we want, because the
/// request's status changes on the backend as the artisan progresses
/// the job.
final serviceRequestDetailsProvider =
    FutureProvider.autoDispose.family<ServiceRequest, String>((ref, requestId) {
  final repo = ref.watch(requestTrackingRepositoryProvider);
  return repo.fetchRequestDetails(requestId);
});

/// Maps an error thrown by [serviceRequestDetailsProvider] into a
/// friendly, user-facing message. Used by the tracking page's error view.
String describeTrackingError(Object error) {
  if (error is ApiException) {
    if (error.statusCode == 404) {
      return 'This request could not be found. It may have been removed.';
    }
    if (error.statusCode == 401) {
      return 'Your session has expired. Please log in again.';
    }
    return error.firstErrorMessage;
  }
  return 'Something went wrong while loading this request.';
}