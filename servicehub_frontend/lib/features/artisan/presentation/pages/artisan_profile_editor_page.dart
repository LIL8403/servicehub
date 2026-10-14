import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:servicehub_frontend/features/artisan/presentation/providers/artisan_verification_providers.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../../customer/presentation/providers/service_catalog_providers.dart';
import '../providers/artisan_profile_providers.dart';
import '../widgets/profile/add_service_sheet.dart';
import '../widgets/profile/experience_stepper.dart';
import '../widgets/profile/profile_section_card.dart';
import '../widgets/profile/services_offered_editor.dart';
import '../widgets/profile/payout_phone_field.dart';

class ArtisanProfileEditorPage extends ConsumerStatefulWidget {
  const ArtisanProfileEditorPage({super.key});

  @override
  ConsumerState<ArtisanProfileEditorPage> createState() =>
      _ArtisanProfileEditorPageState();
}

class _ArtisanProfileEditorPageState
    extends ConsumerState<ArtisanProfileEditorPage> {
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();

  final _payoutPhoneController = TextEditingController();
  String? _payoutPhone;

  int _experienceYears = 0;
  final _selectedServices = <SelectedService>[];
  final _selectedLanguages = <String>{};

  // Snapshot of the loaded profile, used to detect "dirty" state.
  Map<String, dynamic>? _loadedProfile;
  bool _hydrated = false;
  int _bioLength = 0;

  @override
  void initState() {
    super.initState();
    _bioController.addListener(_onBioChanged);
  }

  @override
  void dispose() {
    _bioController.removeListener(_onBioChanged);
    _titleController.dispose();
    _bioController.dispose();
    _payoutPhoneController.dispose();
    super.dispose();
  }

  void _onBioChanged() {
    if (_bioLength != _bioController.text.length) {
      setState(() => _bioLength = _bioController.text.length);
    }
  }

  void _hydrateFrom(Map<String, dynamic> profile) {
    if (_hydrated) return;
    _hydrated = true;
    _loadedProfile = Map<String, dynamic>.from(profile);

    _titleController.text = profile['professional_title']?.toString() ?? '';
    _bioController.text =
        profile['bio']?.toString() ??
        profile['professional_description']?.toString() ??
        '';

    _payoutPhone = profile['payout_phone']?.toString();

    final years = profile['experience_years'];
    _experienceYears = years is num ? years.toInt() : 0;

    final offerings =
        (profile['service_offerings'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];

    _selectedServices
      ..clear()
      ..addAll(
        offerings.map(
          (o) => SelectedService(
            referenceId: o['service_reference']?.toString() ?? '',
            name: '', // Resolved via the catalog below.
          ),
        ),
      );

    final langs =
        (profile['languages'] as List?)?.whereType<String>().toList(
          growable: false,
        ) ??
        const <String>[];
    _selectedLanguages
      ..clear()
      ..addAll(langs);

    if (mounted) setState(() {});
  }

  /// Resolves the display name for each selected service using the
  /// catalog. Called on every build so newly loaded catalog data
  /// populates the list without a second hydration pass.
  List<SelectedService> _resolvedServices(List<ServiceRef> catalog) {
    if (catalog.isEmpty) return _selectedServices;
    return _selectedServices
        .map((s) {
          if (s.name.isNotEmpty) return s;
          final match = catalog.firstWhere(
            (c) => c.id == s.referenceId,
            orElse: () => ServiceRef(
              id: s.referenceId,
              name: 'Unknown service',
              categoryId: '',
              categorySlug: '',
              slug: '',
            ),
          );
          return SelectedService(referenceId: s.referenceId, name: match.name);
        })
        .toList(growable: false);
  }

  bool _hasChanges(List<SelectedService> resolved) {
    final loaded = _loadedProfile;
    final loadedPhone = loaded?['payout_phone']?.toString();
    final currentPhone = _payoutPhone;
    if ((loadedPhone ?? '') != (currentPhone ?? '')) return true;
    if (loaded == null) return false;

    final loadedTitle = loaded['professional_title']?.toString() ?? '';
    if (_titleController.text.trim() != loadedTitle.trim()) return true;

    final loadedBio =
        loaded['bio']?.toString() ??
        loaded['professional_description']?.toString() ??
        '';
    if (_bioController.text.trim() != loadedBio.trim()) return true;

    final loadedYears = loaded['experience_years'];
    final loadedYearsInt = loadedYears is num ? loadedYears.toInt() : 0;
    if (_experienceYears != loadedYearsInt) return true;

    final loadedServices =
        (loaded['service_offerings'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((o) => o['service_reference']?.toString() ?? '')
            .toList(growable: false) ??
        const <String>[];

    final currentIds = resolved
        .map((s) => s.referenceId)
        .toList(growable: false);

    if (loadedServices.length != currentIds.length) return true;
    for (final id in loadedServices) {
      if (!currentIds.contains(id)) return true;
    }

    final loadedLangs =
        (loaded['languages'] as List?)?.whereType<String>().toSet() ??
        <String>{};
    if (loadedLangs.length != _selectedLanguages.length) return true;
    for (final lang in loadedLangs) {
      if (!_selectedLanguages.contains(lang)) return true;
    }

    return false;
  }

  bool _isTitleValid() {
    final len = _titleController.text.trim().length;
    return len >= 2 && len <= 100;
  }

  Future<void> _onSave() async {
    if (!_isTitleValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Professional title must be 2–100 characters.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final resolved = _resolvedServices(
      ref.read(serviceCatalogProvider).valueOrNull ?? const [],
    );

    final payload = <String, dynamic>{
      'professional_title': _titleController.text.trim(),
      'bio': _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      'experience_years': _experienceYears,
      'service_offerings': resolved
          .map((s) => {'service_reference': s.referenceId, 'is_active': true})
          .toList(growable: false),
      'languages': _selectedLanguages.toList(growable: false),
      'payout_phone': _payoutPhone,
    };

    final ok = await ref
        .read(artisanProfileActionProvider.notifier)
        .save(payload);

    if (!mounted) return;

    if (ok) {
      // Invalidate the profile provider so the next screen reads the
      // updated shape. Also invalidate the verification snapshot, so
      // the Professional credentials review reflects the new data.
      ref.invalidate(artisanProfileProvider);
      ref.invalidate(artisanVerificationProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      final error = ref.read(artisanProfileActionProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Could not save. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(artisanProfileProvider, (_, next) {
      next.whenData(_hydrateFrom);
    });
    final initial = ref.read(artisanProfileProvider);
    initial.whenData(_hydrateFrom);

    final catalogAsync = ref.watch(serviceCatalogProvider);
    final action = ref.watch(artisanProfileActionProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: _buildAppBar(context),
      body: initial.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(artisanProfileProvider),
        ),
        data: (_) {
          final catalog = catalogAsync.maybeWhen(
            data: (list) => list,
            orElse: () => const <ServiceRef>[],
          );
          final resolved = _resolvedServices(catalog);
          final hasChanges = _hasChanges(resolved);
          final canSave = hasChanges && _isTitleValid() && !action.isSaving;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _introCard(),
                      const SizedBox(height: AppSpacing.sm + 4),
                      _titleCard(),
                      const SizedBox(height: AppSpacing.sm + 4),
                      _bioCard(),
                      const SizedBox(height: AppSpacing.sm + 4),
                      _experienceCard(),
                      const SizedBox(height: AppSpacing.sm + 4),
                      _servicesCard(resolved, catalog),
                      const SizedBox(height: AppSpacing.sm + 4),
                      _languagesCard(),
                      const SizedBox(height: AppSpacing.sm + 4),
                      _payoutCard(),
                      const SizedBox(height: AppSpacing.sm + 4),
                      _infoCallout(),
                    ],
                  ),
                ),
              ),
              _bottomActions(canSave, action.isSaving),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        onPressed: () => context.pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Text(
            'Edit profile',
            style: AppTypography.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: SvgPicture.asset(
              'assets/brand/logo_symbol.svg',
              width: 28,
              height: 28,
            ),
          ),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.borderLight),
      ),
    );
  }

  Widget _introCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Text(
                  'What customers see',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            'Keep your profile fresh. These details help customers '
            'decide whether to hire you.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleCard() {
    return ProfileSectionCard(
      icon: Icons.badge_outlined,
      label: 'Professional title',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textField(
            controller: _titleController,
            hint: 'e.g. Senior Plumber',
            maxLength: 100,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          Text(
            'A short description of your trade. 2–100 characters.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bioCard() {
    return ProfileSectionCard(
      icon: Icons.description_outlined,
      label: 'About your work',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _bioController,
            maxLines: 5,
            maxLength: 2000,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: InputDecoration(
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              hintText:
                  'Describe your work, your experience, and what makes you reliable.',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.cardLight,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$_bioLength / 2000',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _experienceCard() {
    return ProfileSectionCard(
      icon: Icons.timeline_outlined,
      label: 'Years of experience',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExperienceStepper(
            value: _experienceYears,
            onChanged: (v) => setState(() => _experienceYears = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Between 0 and 60.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _servicesCard(
    List<SelectedService> resolved,
    List<ServiceRef> catalog,
  ) {
    return ProfileSectionCard(
      icon: Icons.handyman_outlined,
      label: 'Services offered',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          '${resolved.length} SELECTED',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 9,
            letterSpacing: 0.4,
          ),
        ),
      ),
      child: ServicesOfferedEditor(
        services: resolved,
        onRemove: (service) {
          setState(() {
            _selectedServices.removeWhere(
              (s) => s.referenceId == service.referenceId,
            );
          });
        },
        onAdd: () => _onAddService(catalog),
      ),
    );
  }

  Future<void> _onAddService(List<ServiceRef> catalog) async {
    final currentIds = _selectedServices.map((s) => s.referenceId).toSet();
    final picked = await showAddServiceSheet(
      context,
      catalog: catalog,
      alreadySelected: currentIds,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedServices.add(
        SelectedService(referenceId: picked.id, name: picked.name),
      );
    });
  }

  Widget _languagesCard() {
    return ProfileSectionCard(
      icon: Icons.language,
      label: 'Languages spoken',
      child: Column(
        children: [
          _languageRow('english', 'English'),
          const SizedBox(height: AppSpacing.sm + 4),
          _languageRow('french', 'French'),
        ],
      ),
    );
  }

  Widget _payoutCard() {
    final configured = _payoutPhone != null && _payoutPhone!.isNotEmpty;

    return ProfileSectionCard(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Payout phone number',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: configured ? AppColors.successTint : AppColors.warningTint,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          configured ? 'CONFIGURED' : 'REQUIRED',
          style: AppTypography.caption.copyWith(
            color: configured ? AppColors.success : AppColors.warning,
            fontWeight: FontWeight.w700,
            fontSize: 9,
            letterSpacing: 0.4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PayoutPhoneField(
            initialValue: _payoutPhone,
            onChanged: (value) => setState(() => _payoutPhone = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.cream.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'You cannot report a job as complete until this is set. '
                    'Your earnings are transferred here after the customer '
                    'confirms the work is done.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageRow(String key, String label) {
    final checked = _selectedLanguages.contains(key);
    return InkWell(
      onTap: () {
        setState(() {
          if (checked) {
            _selectedLanguages.remove(key);
          } else {
            _selectedLanguages.add(key);
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: checked ? AppColors.primary : AppColors.cardLight,
              borderRadius: BorderRadius.circular(6),
              border: checked ? null : Border.all(color: AppColors.borderLight),
            ),
            alignment: Alignment.center,
            child: checked
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.textInverse,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: checked ? AppColors.primary : AppColors.textSecondary,
              fontWeight: checked ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCallout() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 6),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondaryLight.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, size: 20, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Changes take effect immediately. Customers will see '
              'your updated profile the next time they browse.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomActions(bool canSave, bool isSaving) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + 4,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: canSave ? _onSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                disabledBackgroundColor: AppColors.disabledBg,
                disabledForegroundColor: AppColors.disabledText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSaving
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
                  : Text(
                      'Save changes',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: canSave
                            ? AppColors.textInverse
                            : AppColors.disabledText,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextButton(
              onPressed: isSaving ? null : () => context.pop(),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int? maxLength,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLength: maxLength,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.cardLight,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
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
                foregroundColor: AppColors.textInverse,
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
