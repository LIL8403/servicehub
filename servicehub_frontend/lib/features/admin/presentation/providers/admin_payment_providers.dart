import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/admin_payment_repository.dart';

final adminPaymentRepositoryProvider =
    Provider<AdminPaymentRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AdminPaymentRepository(apiService: api);
});

final adminPaymentsFilterProvider =
    StateProvider.autoDispose<AdminPaymentsFilter>(
  (ref) => const AdminPaymentsFilter(),
);

final adminPaymentsPageProvider =
    FutureProvider.autoDispose<AdminPaymentsResponse>((ref) {
  final repo = ref.watch(adminPaymentRepositoryProvider);
  final filter = ref.watch(adminPaymentsFilterProvider);
  return repo.fetch(filter);
});