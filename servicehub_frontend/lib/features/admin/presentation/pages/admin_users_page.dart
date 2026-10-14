import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../data/repositories/admin_user_repository.dart';
import '../providers/admin_user_providers.dart';
import '../widgets/catalog/catalog_empty_state.dart';
import '../widgets/catalog/catalog_search_field.dart';
import '../widgets/users/change_status_dialog.dart';
import '../widgets/users/user_role_pill.dart';
import '../widgets/users/user_status_pill.dart';
import '../widgets/users/users_pagination_bar.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final query = _searchController.text.trim();
      final current = ref.read(adminUsersFilterProvider);
      ref.read(adminUsersFilterProvider.notifier).state = current.copyWith(
        search: query.isEmpty ? null : query,
        clearSearch: query.isEmpty,
        page: 1,
      );
    });
  }

  Future<void> _onChangeStatus(AdminUser user, AdminUsersResponse page) async {
    final authUser = ref.read(authStateProvider).user;
    final isSelf = authUser?.id == user.id;

    // Compute whether this user is the last active admin.
    final activeAdmins = page.users
        .where((u) => u.isActive && u.roles.contains('admin'))
        .length;
    final isLastActiveAdmin =
        user.isActive && user.roles.contains('admin') && activeAdmins <= 1;

    final result = await showChangeStatusDialog(
      context,
      user: user,
      isSelf: isSelf,
      isLastActiveAdmin: isLastActiveAdmin,
    );
    if (result == null || !mounted) return;

    final ok = await ref
        .read(adminUserActionProvider.notifier)
        .updateStatus(
          userId: user.id,
          status: result.status,
          reason: result.reason,
        );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.status == 'suspended'
                ? '${user.name} suspended.'
                : '${user.name} activated.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final err = ref.read(adminUserActionProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Could not update status.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(adminUsersPageProvider);
    final action = ref.watch(adminUserActionProvider);

    // Render the last known page while a new one is loading, so the
    // search field doesn't lose focus and the table doesn't flash.
    final page = pageAsync.valueOrNull;
    final isLoadingFirstTime = pageAsync.isLoading && page == null;
    final hasError = pageAsync.hasError && page == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pageHeader(),
          const SizedBox(height: 24),
          if (isLoadingFirstTime)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 120),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (hasError)
            _ErrorView(
              message: pageAsync.error.toString(),
              onRetry: () => ref.invalidate(adminUsersPageProvider),
            )
          else if (page != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _filterBar(page.meta.total),
                const SizedBox(height: 24),
                _tableCard(page, action.inFlight),
              ],
            ),
        ],
      ),
    );
  }

  Widget _pageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Users',
          style: AppTypography.h2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'All platform accounts — customers, artisans, and '
          'administrators',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _filterBar(int total) {
    final filter = ref.watch(adminUsersFilterProvider);

    return Row(
      children: [
        CatalogSearchField(
          controller: _searchController,
          hintText: 'Search by name, email, or phone...',
        ),
        const SizedBox(width: 16),
        _roleFilter(filter),
        const SizedBox(width: 16),
        _statusFilter(filter),
        const Spacer(),
        Text(
          '$total user${total == 1 ? '' : 's'}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _roleFilter(AdminUsersFilter filter) {
    const options = <({String? value, String label})>[
      (value: null, label: 'All roles'),
      (value: 'customer', label: 'Customers'),
      (value: 'artisan', label: 'Artisans'),
      (value: 'admin', label: 'Admins'),
    ];
    final current = options.firstWhere(
      (o) => o.value == filter.role,
      orElse: () => options.first,
    );

    return PopupMenuButton<String>(
      tooltip: '',
      color: AppColors.cardLight,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      offset: const Offset(0, 48),
      onSelected: (value) {
        ref.read(adminUsersFilterProvider.notifier).state = filter.copyWith(
          role: value == '__all__' ? null : value,
          clearRole: value == '__all__',
          page: 1,
        );
      },
      itemBuilder: (ctx) => [
        for (final o in options)
          PopupMenuItem<String>(
            value: o.value ?? '__all__',
            height: 40,
            child: Text(
              o.label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: o.value == filter.role
                    ? FontWeight.w600
                    : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
      ],
      child: _filterShell(
        width: 180,
        child: Text(
          current.label,
          style: AppTypography.bodySmall.copyWith(
            color: filter.role == null
                ? AppColors.textMuted
                : AppColors.primary,
            fontWeight: filter.role == null ? FontWeight.w500 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _statusFilter(AdminUsersFilter filter) {
    const options = <({String? value, String label})>[
      (value: null, label: 'All statuses'),
      (value: 'active', label: 'Active'),
      (value: 'suspended', label: 'Suspended'),
    ];
    final current = options.firstWhere(
      (o) => o.value == filter.status,
      orElse: () => options.first,
    );

    return PopupMenuButton<String>(
      tooltip: '',
      color: AppColors.cardLight,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      offset: const Offset(0, 48),
      onSelected: (value) {
        ref.read(adminUsersFilterProvider.notifier).state = filter.copyWith(
          status: value == '__all__' ? null : value,
          clearStatus: value == '__all__',
          page: 1,
        );
      },
      itemBuilder: (ctx) => [
        for (final o in options)
          PopupMenuItem<String>(
            value: o.value ?? '__all__',
            height: 40,
            child: Text(
              o.label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: o.value == filter.status
                    ? FontWeight.w600
                    : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
      ],
      child: _filterShell(
        width: 180,
        child: Text(
          current.label,
          style: AppTypography.bodySmall.copyWith(
            color: filter.status == null
                ? AppColors.textMuted
                : AppColors.primary,
            fontWeight: filter.status == null
                ? FontWeight.w500
                : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _filterShell({required double width, required Widget child}) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
          const Icon(Icons.expand_more, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _tableCard(AdminUsersResponse page, bool busy) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: page.users.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CatalogEmptyState(
                title: 'No users found',
                subtitle: 'Try adjusting your filters.',
                icon: Icons.person_off_outlined,
              ),
            )
          : Column(
              children: [
                _headerRow(),
                for (var i = 0; i < page.users.length; i++) ...[
                  _dataRow(page.users[i], page, busy),
                  if (i < page.users.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.borderLight,
                    ),
                ],
                UsersPaginationBar(
                  meta: page.meta,
                  onPrevious: () {
                    final f = ref.read(adminUsersFilterProvider);
                    if (f.page > 1) {
                      ref.read(adminUsersFilterProvider.notifier).state = f
                          .copyWith(page: f.page - 1);
                    }
                  },
                  onNext: () {
                    final f = ref.read(adminUsersFilterProvider);
                    if (f.page < page.meta.lastPage) {
                      ref.read(adminUsersFilterProvider.notifier).state = f
                          .copyWith(page: f.page + 1);
                    }
                  },
                ),
              ],
            ),
    );
  }

  Widget _headerRow() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: _header('USER')),
          const SizedBox(width: 16),
          SizedBox(width: 180, child: _header('ROLES')),
          const SizedBox(width: 16),
          SizedBox(width: 140, child: _header('STATUS')),
          const SizedBox(width: 16),
          SizedBox(width: 140, child: _header('JOINED')),
          SizedBox(
            width: 160,
            child: Align(
              alignment: Alignment.centerRight,
              child: _header('ACTIONS'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String label) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _dataRow(AdminUser user, AdminUsersResponse page, bool busy) {
    final authUser = ref.read(authStateProvider).user;
    final isSelf = authUser?.id == user.id;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.cream,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.initials,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warningTint,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                'You',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.contactLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 180,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final role in user.roles) UserRolePill(role: role),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: Align(
              alignment: Alignment.centerLeft,
              child: UserStatusPill(status: user.status),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: Text(
              _relativeTime(user.createdAt),
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: (busy || isSelf)
                    ? null
                    : () => _onChangeStatus(user, page),
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Change status'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 40),
                  disabledForegroundColor: AppColors.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 14) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    }
    if (diff.inDays >= 1) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    return '${diff.inMinutes} min ago';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
