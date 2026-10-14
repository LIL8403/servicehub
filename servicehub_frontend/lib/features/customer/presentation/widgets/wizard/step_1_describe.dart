import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'photo_upload_section.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../../domain/enums/urgency_level.dart';
import '../../providers/create_request_providers.dart';
import 'ai_assist_card.dart';
import 'urgency_radio_list.dart';
import '../../../domain/models/service_category.dart';
import 'ai_understanding_card.dart';
import '../service_picker_sheet.dart';
import '../../providers/service_catalog_providers.dart';

class Step1Describe extends ConsumerStatefulWidget {
  const Step1Describe({super.key});

  @override
  ConsumerState<Step1Describe> createState() => _Step1DescribeState();
}

class _Step1DescribeState extends ConsumerState<Step1Describe> {
  late final TextEditingController _descriptionController;
  String? _photoError;

  IconData _categoryIcon(String? slug) {
    return ServiceCategories.all
        .firstWhere(
          (c) => c.id == slug,
          orElse: () => ServiceCategories.all.first,
        )
        .icon;
  }

  String? _categoryLabel(AppLocalizations l10n, String? slug) {
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

  @override
  void initState() {
    super.initState();
    final draft = ref.read(createRequestProvider).draft;
    _descriptionController = TextEditingController(text: draft.description);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Entry point — routes to single-capture (camera) or multi-select
  /// (gallery) based on the source.
  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      await _pickSinglePhoto(source);
    } else {
      await _pickMultipleFromGallery();
    }
  }

  Future<void> _pickSinglePhoto(ImageSource source) async {
    final draft = ref.read(createRequestProvider).draft;
    final notifier = ref.read(createRequestProvider.notifier);
    final l10n = AppLocalizations.of(context);

    // Enforce the 5-photo ceiling before even launching the picker.
    if (draft.photoFiles.length >= 5) {
      setState(() => _photoError = l10n.createRequestStep1PhotoLimitReached(5));
      return;
    }

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked == null) return; // user cancelled

      setState(() => _photoError = null);
      final next = List<XFile>.from(draft.photoFiles)..add(picked);
      notifier.setPhotoFiles(next);
    } on PlatformException catch (e) {
      setState(() {
        _photoError = e.code == 'camera_access_denied'
            ? l10n.createRequestStep1CameraDenied
            : l10n.createRequestStep1PhotoPickFailed;
      });
    } catch (_) {
      setState(() => _photoError = l10n.createRequestStep1PhotoPickFailed);
    }
  }

  Future<void> _pickMultipleFromGallery() async {
    final draft = ref.read(createRequestProvider).draft;
    final notifier = ref.read(createRequestProvider.notifier);
    final l10n = AppLocalizations.of(context);

    final remaining = 5 - draft.photoFiles.length;
    if (remaining <= 0) {
      setState(() => _photoError = l10n.createRequestStep1PhotoLimitReached(5));
      return;
    }

    try {
      final picked = await ImagePicker().pickMultiImage(
        imageQuality: 75,
        maxWidth: 1600,
        maxHeight: 1600,
        limit: remaining,
      );
      if (picked.isEmpty) return; // user cancelled

      // Some Android versions ignore `limit`. Enforce it ourselves.
      final accepted = picked.take(remaining).toList();

      setState(() {
        _photoError = picked.length > remaining
            ? l10n.createRequestStep1PhotoLimitReached(5)
            : null;
      });

      final next = List<XFile>.from(draft.photoFiles)..addAll(accepted);
      notifier.setPhotoFiles(next);
    } on PlatformException {
      setState(() => _photoError = l10n.createRequestStep1GalleryDenied);
    } catch (_) {
      setState(() => _photoError = l10n.createRequestStep1PhotoPickFailed);
    }
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
          // Service chip (required — set by the picker on Discover,
          // or by the picker below if the wizard was entered directly).
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _openServicePicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md - 2,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: draft.serviceId == null
                      ? AppColors.warningTint
                      : AppColors.cream.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: draft.serviceId == null
                        ? AppColors.warning
                        : AppColors.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      draft.serviceId == null
                          ? Icons.add_circle_outline
                          : Icons.build_outlined,
                      size: 16,
                      color: draft.serviceId == null
                          ? AppColors.warning
                          : AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm - 2),
                    Text(
                      _serviceLabel(ref) ?? 'Pick a service',
                      style: AppTypography.bodyMedium.copyWith(
                        color: draft.serviceId == null
                            ? AppColors.warning
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Category chip
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                // Return to Service Categories to change the category
                context.go('/service-categories');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md - 2,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categoryIcon(draft.categoryId),
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm - 2),
                    Text(
                      _categoryLabel(l10n, draft.categoryId) ??
                          l10n.servicesTitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Section heading
          Text(
            l10n.createRequestStep1Heading,
            style: AppTypography.h3.copyWith(color: AppColors.primary),
          ),

          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),

          // Description textarea
          Stack(
            children: [
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 1000,
                onChanged: notifier.setDescription,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: l10n.createRequestStep1DescriptionHint,
                  counterText: '',
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                  filled: true,
                  fillColor: AppColors.cardLight,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadii.borderLg,
                    borderSide: const BorderSide(color: AppColors.borderLight),
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
              Positioned(
                bottom: AppSpacing.sm,
                right: AppSpacing.sm + 4,
                child: Text(
                  '${draft.description.length}/1000',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Photo upload
          Text(
            l10n.createRequestStep1PhotoLabel,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.createRequestStep1PhotoHint,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          PhotoUploadSection(
            photos: draft.photoFiles,
            maxPhotos: 5,
            takePhotoLabel: l10n.createRequestStep1TakePhoto,
            galleryLabel: l10n.createRequestStep1ChooseGallery,
            inlineError: _photoError,
            onTakePhoto: () => _pickImage(ImageSource.camera),
            onPickFromGallery: () => _pickImage(ImageSource.gallery),
            onRemove: (photo) {
              final next = List<XFile>.from(draft.photoFiles)..remove(photo);
              notifier.setPhotoFiles(next);
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Urgency selector
          Text(
            l10n.createRequestStep1UrgencyLabel,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          UrgencyRadioList(
            selected: draft.urgency,
            options: [
              UrgencyOption(
                value: UrgencyLevel.low,
                label: l10n.createRequestStep1UrgencyLow,
                description: l10n.createRequestStep1UrgencyLowDesc,
              ),
              UrgencyOption(
                value: UrgencyLevel.medium,
                label: l10n.createRequestStep1UrgencyMedium,
                description: l10n.createRequestStep1UrgencyMediumDesc,
              ),
              UrgencyOption(
                value: UrgencyLevel.high,
                label: l10n.createRequestStep1UrgencyHigh,
                description: l10n.createRequestStep1UrgencyHighDesc,
              ),
            ],
            onChanged: notifier.setUrgency,
          ),

          const SizedBox(height: AppSpacing.xl),

          // AI Assist toggle
          // Optional "Improve with AI" — advisory only, never mutates the
          // draft without the user's explicit acceptance.
          AiUnderstandingCard(
            description: draft.description,
            serviceId: draft.categoryId,
            onAccept: (understanding) {
              // Apply only what the user explicitly accepts.
              if (understanding.urgency != null) {
                notifier.setUrgency(understanding.urgency);
              }
              final rewritten = understanding.rewrittenDescription;
              if (rewritten != null && rewritten.trim().isNotEmpty) {
                _descriptionController.text = rewritten;
                notifier.setDescription(rewritten);
              }
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Existing toggle kept as a separate concept: "let AI assist matching
          // after submission". This is the flag sent to the backend on submit.
          AiAssistCard(
            enabled: draft.aiAssistEnabled,
            onChanged: notifier.setAiAssist,
            title: l10n.createRequestStep1AiTitle,
            description: l10n.createRequestStep1AiDescription,
          ),
        ],
      ),
    );
  }

  String? _serviceLabel(WidgetRef ref) {
    final draft = ref.watch(createRequestProvider).draft;
    if (draft.serviceId == null) return null;

    final catalogAsync = ref.watch(serviceCatalogProvider);
    return catalogAsync.maybeWhen(
      data: (catalog) {
        for (final s in catalog) {
          if (s.id == draft.serviceId) return s.name;
        }
        return 'Selected service';
      },
      orElse: () => 'Loading…',
    );
  }

  Future<void> _openServicePicker(BuildContext context) async {
    final draft = ref.read(createRequestProvider).draft;
    final categorySlug = draft.categoryId ?? '';
    if (categorySlug.isEmpty) return;

    final service = await showServicePickerSheet(
      context,
      categorySlug: categorySlug,
      current: null,
    );
    if (service == null) return;
    if (!context.mounted) return;

    ref
        .read(createRequestProvider.notifier)
        .setService(serviceId: service.id, categoryId: categorySlug);
    setState(() {});
  }
}
