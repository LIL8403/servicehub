import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../providers/create_request_providers.dart';
import '../providers/submit_request_providers.dart';
import '../widgets/wizard/step_1_describe.dart';
import '../widgets/wizard/step_2_location.dart';
import '../widgets/wizard/step_3_schedule.dart';
import '../widgets/wizard/step_4_review.dart';
import '../widgets/wizard/wizard_progress.dart';

class CreateRequestPage extends ConsumerStatefulWidget {
  const CreateRequestPage({super.key, required this.initialCategory});

  final String initialCategory;

  @override
  ConsumerState<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends ConsumerState<CreateRequestPage> {
  late final String _initialServiceId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    _initialServiceId =
        GoRouterState.of(context).uri.queryParameters['serviceId'] ?? '';

    Future.microtask(() {
      final notifier = ref.read(createRequestProvider.notifier);
      notifier.setCategory(widget.initialCategory);
      if (_initialServiceId.isNotEmpty) {
        notifier.setService(
          serviceId: _initialServiceId,
          categoryId: widget.initialCategory,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(submitProvider);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(createRequestProvider);
    final notifier = ref.read(createRequestProvider.notifier);
    final currentStep = state.currentStep;

    return Scaffold(
      backgroundColor: AppColors.cardLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {
            if (currentStep == 0) {
              context.go('/service-categories');
            } else {
              notifier.previousStep();
            }
          },
        ),
        title: Text(
          l10n.createRequestTitle,
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
            WizardProgress(
              currentStep: currentStep,
              totalSteps: 4,
              stepLabel: l10n.createRequestStepLabel(currentStep + 1, 4),
            ),
            Expanded(child: _buildStepBody(currentStep, state)),
            _buildBottomCta(
              context,
              l10n,
              currentStep,
              state,
              notifier,
              submitState,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody(int step, CreateRequestState state) {
    switch (step) {
      case 0:
        return const Step1Describe();
      case 1:
        return const Step2Location();
      case 2:
        return const Step3Schedule();
      case 3:
        return const Step4Review();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomCta(
    BuildContext context,
    AppLocalizations l10n,
    int step,
    CreateRequestState state,
    CreateRequestNotifier notifier,
    SubmitState submitState,
  ) {
    final canContinue = switch (step) {
      0 => state.draft.isStep1Valid,
      1 => state.draft.isStep2Valid,
      2 => state.draft.isStep3Valid,
      _ => true,
    };

    final isEnabled = canContinue && !submitState.isSubmitting;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        border: const Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm + AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (submitState.errorMessage != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.errorTint,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 20,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      submitState.errorMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isEnabled
                  ? () async {
                      if (step < 3) {
                        notifier.nextStep();
                        return;
                      }

                      final success = await ref
                          .read(submitProvider.notifier)
                          .submit(state.draft);

                      if (!context.mounted) return;

                      if (success) {
                        final result = ref.read(submitProvider);
                        final aiAssist = result.submittedAiAssist ?? false;
                        final requestId = result.submittedId ?? '';

                        notifier.reset();

                        context.go(
                          '/request-success'
                          '?requestId=$requestId'
                          '&aiAssist=$aiAssist',
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                disabledBackgroundColor: AppColors.disabledBg,
                disabledForegroundColor: AppColors.disabledText,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: submitState.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textInverse,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          step < 3
                              ? l10n.createRequestContinue
                              : l10n.createRequestSubmit,
                          style: AppTypography.bodyLarge.copyWith(
                            color: isEnabled
                                ? AppColors.textInverse
                                : AppColors.disabledText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isEnabled) ...[
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(
                            Icons.arrow_forward,
                            size: 20,
                            color: AppColors.textInverse,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
