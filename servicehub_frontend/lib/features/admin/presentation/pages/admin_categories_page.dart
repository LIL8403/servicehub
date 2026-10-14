import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../data/repositories/admin_category_repository.dart';
import '../providers/admin_category_providers.dart';
import '../widgets/catalog/catalog_action_icon.dart';
import '../widgets/catalog/catalog_empty_state.dart';
import '../widgets/catalog/catalog_search_field.dart';
import '../widgets/catalog/catalog_slug_icon.dart';
import '../widgets/catalog/catalog_status_pill.dart';
import '../widgets/categories/category_delete_dialog.dart';
import '../widgets/categories/category_form_dialog.dart';

class AdminCategoriesPage extends ConsumerStatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  ConsumerState<AdminCategoriesPage> createState() =>
      _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends ConsumerState<AdminCategoriesPage> {
  final _searchController = TextEditingController();
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

  List<AdminCategory> _applyFilters(List<AdminCategory> all) {
    final query = _searchController.text.trim().toLowerCase();
    return all
        .where((c) {
          if (_showOnlyActive && !c.isActive) return false;
          if (query.isNotEmpty) {
            final matchesName = c.name.toLowerCase().contains(query);
            final matchesSlug = c.slug.toLowerCase().contains(query);
            if (!matchesName && !matchesSlug) return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  Future<void> _onCreate() async {
    final result = await showCategoryFormDialog(context);
    if (result == null || !mounted) return;

    final ok = await ref
        .read(adminCategoryActionProvider.notifier)
        .create(
          name: result.name,
          description: result.description,
          isActive: result.isActive,
        );

    if (!mounted) return;

    if (ok) {
      _showSnack('Category created.', success: true);
    } else {
      final err = ref.read(adminCategoryActionProvider).errorMessage;
      _showSnack(err ?? 'Could not create category.', success: false);
    }
  }

  Future<void> _onEdit(AdminCategory category) async {
    final result = await showCategoryFormDialog(context, existing: category);
    if (result == null || !mounted) return;

    final ok = await ref
        .read(adminCategoryActionProvider.notifier)
        .update(
          id: category.id,
          name: result.name,
          description: result.description,
          isActive: result.isActive,
        );

    if (!mounted) return;

    if (ok) {
      _showSnack('Category updated.', success: true);
    } else {
      final err = ref.read(adminCategoryActionProvider).errorMessage;
      _showSnack(err ?? 'Could not update category.', success: false);
    }
  }

  Future<void> _onToggle(AdminCategory category) async {
    final ok = await ref
        .read(adminCategoryActionProvider.notifier)
        .update(
          id: category.id,
          name: category.name,
          description: category.description.isEmpty
              ? null
              : category.description,
          isActive: !category.isActive,
        );

    if (!mounted) return;

    if (ok) {
      _showSnack(
        category.isActive
            ? '${category.name} deactivated.'
            : '${category.name} activated.',
        success: true,
      );
    } else {
      final err = ref.read(adminCategoryActionProvider).errorMessage;
      _showSnack(err ?? 'Could not update category.', success: false);
    }
  }

  Future<void> _onDelete(AdminCategory category) async {
    final confirmed = await showCategoryDeleteDialog(
      context,
      categoryName: category.name,
    );
    if (confirmed != true || !mounted) return;

    try {
      final ok = await ref
          .read(adminCategoryActionProvider.notifier)
          .delete(category.id);

      if (!mounted) return;

      if (ok) {
        _showSnack('Category deleted.', success: true);
      } else {
        final err = ref.read(adminCategoryActionProvider).errorMessage;
        _showSnack(err ?? 'Could not delete category.', success: false);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Delete failed: $e', success: false);
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
    final async = ref.watch(adminCategoriesProvider);
    final action = ref.watch(adminCategoryActionProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 120),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(adminCategoriesProvider),
        ),
        data: (all) {
          final filtered = _applyFilters(all);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _pageHeader(action.inFlight),
              const SizedBox(height: 24),
              _filterBar(all.length),
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
                'Service categories',
                style: AppTypography.h2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage the top-level groups that organize the '
                'individual services',
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
          label: const Text('New category'),
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

  Widget _filterBar(int total) {
    return Row(
      children: [
        CatalogSearchField(
          controller: _searchController,
          hintText: 'Search categories...',
        ),
        const SizedBox(width: 16),
        _statusChip(),
        const Spacer(),
        Text(
          '$total categor${total == 1 ? 'y' : 'ies'}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
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

  Widget _tableCard(List<AdminCategory> rows, bool busy) {
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
                title: 'No categories found',
                subtitle:
                    'Try adjusting your filters, or create a new '
                    'category.',
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
          SizedBox(width: 140, child: _header('SERVICES')),
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

  Widget _dataRow(AdminCategory c, bool busy) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                CatalogSlugIcon(slug: c.slug),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.name,
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
                        c.description.isEmpty ? c.slug : c.description,
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
          SizedBox(width: 140, child: _servicesCountPill(c.serviceCount)),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerLeft,
              child: CatalogStatusPill(isActive: c.isActive),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: Text(
              _relativeTime(c.createdAt),
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
                    tooltip: 'Edit category',
                    onTap: busy ? () {} : () => _onEdit(c),
                  ),
                  const SizedBox(width: 4),
                  CatalogActionIcon(
                    icon: c.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    tooltip: c.isActive
                        ? 'Deactivate category'
                        : 'Activate category',
                    onTap: busy ? () {} : () => _onToggle(c),
                  ),
                  const SizedBox(width: 4),
                  CatalogActionIcon(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete category',
                    color: AppColors.error,
                    disabled: c.serviceCount > 0,
                    disabledReason: 'Remove all services first',
                    onTap: busy ? () {} : () => _onDelete(c),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _servicesCountPill(int count) {
    final label = count == 0
        ? 'No services'
        : '$count service${count == 1 ? '' : 's'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: count == 0 ? AppColors.textMuted : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
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
        'Showing $count of $count categor${count == 1 ? 'y' : 'ies'}',
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
