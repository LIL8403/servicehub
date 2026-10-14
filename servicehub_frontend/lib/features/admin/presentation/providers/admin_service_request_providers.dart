import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/admin_service_request_repository.dart';

final adminServiceRequestRepositoryProvider =
    Provider<AdminServiceRequestRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AdminServiceRequestRepository(apiService: api);
});

final adminServiceRequestsFilterProvider =
    StateProvider.autoDispose<AdminServiceRequestsFilter>(
  (ref) => const AdminServiceRequestsFilter(),
);

final adminServiceRequestsPageProvider =
    FutureProvider.autoDispose<AdminServiceRequestsResponse>((ref) {
  final repo = ref.watch(adminServiceRequestRepositoryProvider);
  final filter = ref.watch(adminServiceRequestsFilterProvider);
  return repo.fetch(filter);
});