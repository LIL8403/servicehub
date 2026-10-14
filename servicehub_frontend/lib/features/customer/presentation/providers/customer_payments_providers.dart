import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/customer_payments_repository.dart';
import '../../domain/models/payment_record.dart';

final customerPaymentsRepositoryProvider =
    Provider<CustomerPaymentsRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return CustomerPaymentsRepository(apiService: api);
});

final customerPaymentsProvider =
    FutureProvider.autoDispose<List<PaymentRecord>>((ref) {
  final repo = ref.watch(customerPaymentsRepositoryProvider);
  return repo.list();
});