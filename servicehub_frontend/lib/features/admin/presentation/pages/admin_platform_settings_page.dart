import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servicehub_frontend/features/admin/data/repositories/admin_platform_settings_repository.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../providers/admin_platform_settings_providers.dart';
import '../widgets/settings/commission_form_card.dart';
import '../widgets/settings/commission_preview_card.dart';

class AdminPlatformSettingsPage extends ConsumerStatefulWidget {
  const AdminPlatformSettingsPage({super.key});

  @override
  ConsumerState<AdminPlatformSettingsPage> createState() =>
      _AdminPlatformSettingsPageState();
}

class _AdminPlatformSettingsPageState
    extends ConsumerState<AdminPlatformSettingsPage> {
  /// The rate the preview is currently rendering. Seeded from the
  /// saved rate, updated whenever the form's input changes.
  double? _previewRatePercent;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(commissionSettingsProvider);
    final action = ref.watch(commissionActionProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: settingsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 120),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(commissionSettingsProvider),
        ),
        data: (settings) {
          // Seed the preview rate from the loaded settings on first
          // render.
          _previewRatePercent ??= settings.ratePercent;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _pageHeader(),
              const SizedBox(height: 24),
              _twoColumnLayout(settings, action),
            ],
          );
        },
      ),
    );
  }

  Widget _pageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platform settings',
          style: AppTypography.h2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configure platform-wide settings that affect every '
          'transaction',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _twoColumnLayout(
    CommissionSettings settings,
    CommissionActionState action,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: CommissionFormCard(
            currentSettings: settings,
            isSaving: action.inFlight,
            onRateChanged: (percent) {
              setState(() => _previewRatePercent = percent);
            },
            onSubmit: (rateDecimal, reason) async {
              final ok =
                  await ref.read(commissionActionProvider.notifier).update(
                        rate: rateDecimal,
                        reason: reason,
                      );
              if (!mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Commission updated to '
                      '${(_previewRatePercent ?? 0).toStringAsFixed(2)}%. '
                      'Audit event logged.',
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.success,
                  ),
                );
                // Reset preview to the newly saved rate.
                setState(() {
                  _previewRatePercent =
                      (rateDecimal * 100).toDouble();
                });
              } else {
                final err =
                    ref.read(commissionActionProvider).errorMessage;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err ?? 'Could not save.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 5,
          child: CommissionPreviewCard(
            ratePercent: _previewRatePercent ?? settings.ratePercent,
          ),
        ),
      ],
    );
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