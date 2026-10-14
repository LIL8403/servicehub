import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../providers/create_request_providers.dart';
import 'date_picker_row.dart';
import 'time_window_pickers.dart';

class Step3Schedule extends ConsumerStatefulWidget {
  const Step3Schedule({super.key});

  @override
  ConsumerState<Step3Schedule> createState() => _Step3ScheduleState();
}

class _Step3ScheduleState extends ConsumerState<Step3Schedule> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(createRequestProvider).draft;
    _notesController =
        TextEditingController(text: draft.additionalNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(createRequestProvider);
    final notifier = ref.read(createRequestProvider.notifier);
    final draft = state.draft;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          Text(
            l10n.createRequestStep3Heading,
            style: AppTypography.h3.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm - 4),
          Text(
            l10n.createRequestStep3Subheading,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Date picker
          DatePickerRow(
            selectedDate: draft.preferredDate,
            onSelected: (date) {
              notifier.setSchedule(
                preferredDate: date,
                preferredStartTime: draft.preferredStartTime,
                preferredEndTime: draft.preferredEndTime,
                isFlexible: draft.isFlexible,
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Time window pickers — hidden when flexible
          if (!draft.isFlexible) ...[
            TimeWindowPickers(
              earliest: draft.preferredStartTime,
              latest: draft.preferredEndTime,
              onEarliestChanged: (time) {
                notifier.setSchedule(
                  preferredDate: draft.preferredDate,
                  preferredStartTime: time,
                  preferredEndTime: draft.preferredEndTime,
                  isFlexible: draft.isFlexible,
                );
              },
              onLatestChanged: (time) {
                notifier.setSchedule(
                  preferredDate: draft.preferredDate,
                  preferredStartTime: draft.preferredStartTime,
                  preferredEndTime: time,
                  isFlexible: draft.isFlexible,
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Flexible toggle card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: AppRadii.borderLg,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.access_time,
                    size: 24,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.createRequestStep3FlexibleTitle,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: draft.isFlexible,
                            onChanged: (enabled) {
                              notifier.setSchedule(
                                preferredDate: draft.preferredDate,
                                preferredStartTime:
                                    draft.preferredStartTime,
                                preferredEndTime: draft.preferredEndTime,
                                isFlexible: enabled,
                              );
                            },
                            activeThumbColor: AppColors.secondary,
                            activeTrackColor: AppColors.secondary
                                .withValues(alpha: 0.35),
                            inactiveThumbColor: AppColors.cardLight,
                            inactiveTrackColor: AppColors.borderLight,
                          ),
                        ],
                      ),
                      Text(
                        l10n.createRequestStep3FlexibleDescription,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Additional notes
          Text(
            l10n.createRequestStep3NotesLabel,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          TextField(
            controller: _notesController,
            maxLines: 2,
            onChanged: notifier.setAdditionalNotes,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: l10n.createRequestStep3NotesHint,
              contentPadding: const EdgeInsets.all(AppSpacing.md - 2),
              filled: true,
              fillColor: AppColors.cardLight,
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.borderLg,
                borderSide: const BorderSide(
                  color: AppColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.borderLg,
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}