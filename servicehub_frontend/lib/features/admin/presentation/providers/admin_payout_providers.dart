import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/admin_payout_repository.dart';

final adminPayoutRepositoryProvider =
    Provider<AdminPayoutRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AdminPayoutRepository(apiService: api);
});

final adminPayoutsFilterProvider =
    StateProvider.autoDispose<AdminPayoutsFilter>(
  (ref) => const AdminPayoutsFilter(),
);

final adminPayoutsPageProvider =
    FutureProvider.autoDispose<AdminPayoutsResponse>((ref) {
  final repo = ref.watch(adminPayoutRepositoryProvider);
  final filter = ref.watch(adminPayoutsFilterProvider);
  return repo.fetch(filter);
});