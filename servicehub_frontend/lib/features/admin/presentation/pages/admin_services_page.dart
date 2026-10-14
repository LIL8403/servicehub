import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../data/repositories/admin_category_repository.dart';
import '../../data/repositories/admin_service_repository.dart';
import '../providers/admin_category_providers.dart';
import '../providers/admin_service_providers.dart';
import '../widgets/catalog/catalog_action_icon.dart';
import '../widgets/catalog/catalog_empty_state.dart';
import '../widgets/catalog/catalog_search_field.dart';
import '../widgets/catalog/catalog_slug_icon.dart';
import '../widgets/catalog/catalog_status_pill.dart';
import '../widgets/services/service_deactivate_dialog.dart';
import '../widgets/services/service_form_dialog.dart';

class AdminServicesPage extends ConsumerStatefulWidget {
  const AdminServicesPage({super.key});

  @override
  ConsumerState<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends ConsumerState<AdminServicesPage> {
  final _searchController = TextEditingController();
  String? _categoryFilter;
  bool _showOnlyActive = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminService> _applyFilters(List<AdminService> all) {
    final query = _searchController.text.trim().toLowerCase();
    return all
        .where((s) {
          if (_showOnlyActive && !s.isActive) return false;
          if (_categoryFilter != null && s.categoryId != _categoryFilter) {
            return false;
          }
          if (query.isNotEmpty) {
            final matchesName = s.name.toLowerCase().contains(query);
            final matchesSlug = s.slug.toLowerCase().contains(query);
            final matchesCategory = s.categoryName.toLowerCase().contains(
              query,
            );
            if (!matchesName && !matchesSlug && !matchesCategory) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
  }

  Future<void> _onCreate() async {
    final result = await showServiceFormDialog(context);
    if (result == null || !mounted) return;

    final ok = await ref
        .read(adminServiceActionProvider.notifier)
        .create(
          categoryId: result.categoryId,
          name: result.name,
          description: result.description,
          isActive: result.isActive,
        );

    if (!mounted) return;

    if (ok) {
      _showSnack('Service created.', success: true);
    } else {
      final err = ref.read(adminServiceActionProvider).errorMessage;
      _showSnack(err ?? 'Could not create service.', success: false);
    }
  }

  Future<void> _onEdit(AdminService service) async {
    final result = await showServiceFormDialog(context, existing: service);
    if (result == null || !mounted) return;

    final ok = await ref
        .read(adminServiceActionProvider.notifier)
        .update(
          id: service.id,
          categoryId: result.categoryId,
          name: result.name,
          description: result.description,
          isActive: result.isActive,
        );

    if (!mounted) return;

    if (ok) {
      _showSnack('Service updated.', success: true);
    } else {
      final err = ref.read(adminServiceActionProvider).errorMessage;
      _showSnack(err ?? 'Could not update service.', success: false);
    }
  }

  Future<void> _onToggle(AdminService service) async {
    // When toggling to inactive, show the confirmation dialog.
    if (service.isActive) {
      final confirmed = await showServiceDeactivateDialog(
        context,
        serviceName: service.name,
      );
      if (confirmed != true || !mounted) return;
    }

    final ok = await ref
        .read(adminServiceActionProvider.notifier)
        .update(
          id: service.id,
          categoryId: service.categoryId,
          name: service.name,
          description: service.description.isEmpty ? null : service.description,
          isActive: !service.isActive,
        );

    if (!mounted) return;

    if (ok) {
      _showSnack(
        service.isActive
            ? '${service.name} deactivated.'
            : '${service.name} activated.',
        success: true,
      );
    } else {
      final err = ref.read(adminServiceActionProvider).errorMessage;
      _showSnack(err ?? 'Could not update service.', success: false);
    }
  }

  void _showSnack(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminServicesProvider);
    final categoriesAsync = ref.watch(adminCategoriesProvider);
    final action = ref.watch(adminServiceActionProvider);

    final categories = categoriesAsync.valueOrNull ?? const <AdminCategory>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 120),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(adminServicesProvider),
        ),
        data: (all) {
          final filtered = _applyFilters(all);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _pageHeader(action.inFlight),
              const SizedBox(height: 24),
              _filterBar(all.length, categories),
              const SizedBox(height: 24),
              _tableCard(filtered, action.inFlight),
            ],
          );
        },
      ),
    );
  }

  Widget _pageHeader(bool busy) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Services',
                style: AppTypography.h2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage the individual services offered across all '
                'categories',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        ElevatedButton.icon(
          onPressed: busy ? null : _onCreate,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New service'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.disabledBg,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            minimumSize: const Size(0, 40),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterBar(int total, List<AdminCategory> categories) {
    return Row(
      children: [
        CatalogSearchField(
          controller: _searchController,
          hintText: 'Search services...',
        ),
        const SizedBox(width: 16),
        _categoryDropdown(categories),
        const SizedBox(width: 16),
        _statusChip(),
        const Spacer(),
        Text(
          '$total service${total == 1 ? '' : 's'}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _categoryDropdown(List<AdminCategory> categories) {
    const allValue = '__all__';
    final current = _categoryFilter ?? allValue;
    final label = _categoryFilter == null
        ? 'All categories'
        : categories
              .firstWhere(
                (c) => c.id == _categoryFilter,
                orElse: () => categories.first,
              )
              .name;

    return PopupMenuButton<String>(
      tooltip: '',
      color: AppColors.cardLight,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      offset: const Offset(0, 48),
      onSelected: (value) => setState(() {
        _categoryFilter = value == allValue ? null : value;
      }),
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          value: allValue,
          height: 40,
          child: Text(
            'All categories',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: _categoryFilter == null
                  ? FontWeight.w600
                  : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        for (final c in categories)
          PopupMenuItem<String>(
            value: c.id,
            height: 40,
            child: Text(
              c.name,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: c.id == current ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
      ],
      child: Container(
        width: 200,
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
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: _categoryFilter == null
                      ? AppColors.textMuted
                      : AppColors.primary,
                  fontWeight: _categoryFilter == null
                      ? FontWeight.w500
                      : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(Icons.expand_more, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _statusChip() {
    return Material(
      color: AppColors.cardLight,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        borderRadius: BorderRadius.circular(9999),
        onTap: () => setState(() => _showOnlyActive = !_showOnlyActive),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: _showOnlyActive
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Active only',
                style: AppTypography.bodySmall.copyWith(
                  color: _showOnlyActive
                      ? AppColors.primary
                      : AppColors.textMuted,
                  fontWeight: _showOnlyActive
                      ? FontWeight.w600
                      : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              if (_showOnlyActive) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _showOnlyActive = false),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableCard(List<AdminService> rows, bool busy) {
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
      child: rows.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CatalogEmptyState(
                title: 'No services found',
                subtitle:
                    'Try adjusting your filters, or create a new '
                    'service.',
              ),
            )
          : Column(
              children: [
                _headerRow(),
                for (var i = 0; i < rows.length; i++) ...[
                  _dataRow(rows[i], busy),
                  if (i < rows.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.borderLight,
                    ),
                ],
                _footer(rows.length),
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
          Expanded(flex: 5, child: _header('NAME')),
          const SizedBox(width: 16),
          SizedBox(width: 200, child: _header('CATEGORY')),
          const SizedBox(width: 16),
          SizedBox(width: 120, child: _header('STATUS')),
          const SizedBox(width: 16),
          SizedBox(width: 140, child: _header('CREATED')),
          SizedBox(
            width: 120,
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

  Widget _dataRow(AdminService s, bool busy) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                CatalogSlugIcon(slug: s.slug),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.description.isEmpty ? s.slug : s.description,
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
            width: 200,
            child: Text(
              s.categoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerLeft,
              child: CatalogStatusPill(isActive: s.isActive),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: Text(
              _relativeTime(s.createdAt),
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CatalogActionIcon(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit service',
                    onTap: busy ? () {} : () => _onEdit(s),
                  ),
                  const SizedBox(width: 4),
                  CatalogActionIcon(
                    icon: s.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    tooltip: s.isActive
                        ? 'Deactivate service'
                        : 'Activate service',
                    onTap: busy ? () {} : () => _onToggle(s),
                  ),
                  const SizedBox(width: 4),
                  CatalogActionIcon(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete service',
                    color: AppColors.error,
                    disabled: true,
                    disabledReason:
                        'Deactivate instead of deleting — services '
                        'can be reactivated any time',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(int count) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        'Showing $count of $count service${count == 1 ? '' : 's'}',
        style: AppTypography.caption.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
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
