import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/admin_dashboard_repository.dart';

final adminDashboardRepositoryProvider =
    Provider<AdminDashboardRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AdminDashboardRepository(apiService: api);
});

final adminDashboardProvider =
    FutureProvider.autoDispose<AdminDashboardData>((ref) {
  final repo = ref.watch(adminDashboardRepositoryProvider);
  return repo.fetch();
});