import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/admin_audit_log_repository.dart';

final adminAuditLogRepositoryProvider =
    Provider<AdminAuditLogRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AdminAuditLogRepository(apiService: api);
});

final adminAuditLogsFilterProvider =
    StateProvider.autoDispose<AdminAuditLogsFilter>(
  (ref) => const AdminAuditLogsFilter(),
);

final adminAuditLogsPageProvider =
    FutureProvider.autoDispose<AdminAuditLogsResponse>((ref) {
  final repo = ref.watch(adminAuditLogRepositoryProvider);
  final filter = ref.watch(adminAuditLogsFilterProvider);
  return repo.fetch(filter);
});