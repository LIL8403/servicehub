import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/service_category.dart';
import '../widgets/category_card.dart';
import '../widgets/login_prompt_sheet.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ServiceCategoriesPage extends ConsumerStatefulWidget {
  const ServiceCategoriesPage({super.key});

  @override
  ConsumerState<ServiceCategoriesPage> createState() =>
      _ServiceCategoriesPageState();
}

class _ServiceCategoriesPageState extends ConsumerState<ServiceCategoriesPage> {
  String? _selectedCategoryId;

  void _selectCategory(String id) {
    setState(() {
      _selectedCategoryId = _selectedCategoryId == id ? null : id;
    });
  }

  Future<void> _onBookNow() async {
    final selectedId = _selectedCategoryId;
    if (selectedId == null) return;

    final authState = ref.read(authStateProvider);

    if (authState is! AuthAuthenticated) {
      final result = await showLoginPromptSheet(context);

      if (!mounted) return;

      switch (result) {
        case LoginPromptResult.continueBrowsing:
          return;
        case LoginPromptResult.login:
          // Navigate to the protected route — the router will redirect
          // to /login?redirect=/create-request?category=... automatically
          context.go('/create-request?category=$selectedId');
          return;
        case LoginPromptResult.register:
          context.go('/create-request?category=$selectedId');
          return;
      }
    }

    // Authenticated — proceed directly
    if (!mounted) return;
    context.go('/create-request?category=$selectedId');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasSelection = _selectedCategoryId != null;

    return Scaffold(
      backgroundColor: AppColors.cardLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.go('/landing'),
        ),
        title: Text(
          l10n.servicesTitle,
          style: AppTypography.h3.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    Text(
                      l10n.servicesHeading,
                      style: AppTypography.h2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.servicesSubheading,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Category list
                    ...ServiceCategories.all.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm + AppSpacing.xs,
                        ),
                        child: CategoryCard(
                          category: category,
                          title: _titleFor(l10n, category.slug),
                          description: _descriptionFor(l10n, category.slug),
                          isSelected: _selectedCategoryId == category.id,
                          onTap: () => _selectCategory(category.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Fixed bottom action
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                border: const Border(
                  top: BorderSide(color: AppColors.borderLight, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm + AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: hasSelection
                      ? ElevatedButton(
                          onPressed: _onBookNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textInverse,
                            shape: const StadiumBorder(),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.servicesBookNow,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textInverse,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Icon(
                                Icons.arrow_forward,
                                size: 20,
                                color: AppColors.textInverse,
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor: AppColors.disabledBg,
                            disabledForegroundColor: AppColors.disabledText,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: Text(
                            l10n.servicesBookNow,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.disabledText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleFor(AppLocalizations l10n, String slug) {
    switch (slug) {
      case 'plumbing':
        return l10n.categoryPlumbing;
      case 'electrical':
        return l10n.categoryElectrical;
      case 'carpentry':
        return l10n.categoryCarpentry;
      case 'painting':
        return l10n.categoryPainting;
      case 'masonry':
        return l10n.categoryMasonry;
      case 'mechanics':
        return l10n.categoryMechanics;
      default:
        return slug;
    }
  }

  String _descriptionFor(AppLocalizations l10n, String slug) {
    switch (slug) {
      case 'plumbing':
        return l10n.categoryPlumbingDesc;
      case 'electrical':
        return l10n.categoryElectricalDesc;
      case 'carpentry':
        return l10n.categoryCarpentryDesc;
      case 'painting':
        return l10n.categoryPaintingDesc;
      case 'masonry':
        return l10n.categoryMasonryDesc;
      case 'mechanics':
        return l10n.categoryMechanicsDesc;
      default:
        return '';
    }
  }
}
