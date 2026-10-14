import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/location/location_permission_dialog.dart';
import '../../../../../core/location/location_providers.dart';
import '../../../../../core/location/location_service.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../ui/core/theme/app_colors.dart';
import '../../../../../ui/core/theme/app_radii.dart';
import '../../../../../ui/core/theme/app_spacing.dart';
import '../../../../../ui/core/theme/app_typography.dart';
import '../../providers/create_request_providers.dart';

class Step2Location extends ConsumerStatefulWidget {
  const Step2Location({super.key});

  @override
  ConsumerState<Step2Location> createState() => _Step2LocationState();
}

class _Step2LocationState extends ConsumerState<Step2Location> {
  late final TextEditingController _addressController;

  Timer? _debounce;
  bool _isGeocoding = false;
  bool _isLocating = false;
  String? _searchError;

  GeoPoint? _suggestion;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(createRequestProvider).draft;
    _addressController = TextEditingController(
      text: draft.formattedAddress ?? '',
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    final l10n = AppLocalizations.of(context);

    final allowed = await showLocationPrePermissionDialog(context);
    if (!allowed) return;

    setState(() {
      _isLocating = true;
      _searchError = null;
      _suggestion = null;
    });

    final service = ref.read(locationServiceProvider);
    final result = await service.getCurrentPosition();

    if (!mounted) return;

    if (!result.isGranted || result.point == null) {
      switch (result.availability) {
        case LocationAvailability.deniedForever:
          await showLocationSettingsDialog(context);
          break;
        default:
          setState(() {
            _searchError =
                result.errorMessage ??
                l10n.createRequestStep2LocationUnavailable;
          });
      }
      if (mounted) setState(() => _isLocating = false);
      return;
    }

    final point = result.point!;
    final label = await service.reverseGeocode(point.latitude, point.longitude);

    if (!mounted) return;

    final display = (label ?? '').trim().isNotEmpty
        ? label!
        : '${point.latitude.toStringAsFixed(4)}, '
              '${point.longitude.toStringAsFixed(4)}';

    _addressController.text = display;
    ref.read(createRequestProvider.notifier).setLocation(
          latitude: point.latitude,
          longitude: point.longitude,
          formattedAddress: display,
        );

    setState(() {
      _isLocating = false;
      _searchError = null;
      _suggestion = null;
    });
  }

  void _onAddressChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();

    setState(() {
      _suggestion = null;
      _searchError = null;
    });

    // Store the typed text with NO coordinates. The backend will
    // geocode on submit if the customer doesn't pick a suggestion.
    // Never send a (0,0) sentinel — MongoDB would store Null Island.
    ref.read(createRequestProvider.notifier).clearLocation();

    if (trimmed.isNotEmpty) {
      ref.read(createRequestProvider.notifier).setAddressOnly(trimmed);
    }

    if (trimmed.length < 4) {
      setState(() => _isGeocoding = false);
      return;
    }

    setState(() => _isGeocoding = true);

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      final service = ref.read(locationServiceProvider);
      final point = await service.geocode(trimmed);
      if (!mounted) return;

      setState(() {
        _isGeocoding = false;
        _suggestion = point;
      });
    });
  }

  void _acceptSuggestion() {
    final point = _suggestion;
    if (point == null) return;

    final label = point.label ?? _addressController.text.trim();
    _addressController.text = label;

    ref.read(createRequestProvider.notifier).setLocation(
          latitude: point.latitude,
          longitude: point.longitude,
          formattedAddress: label,
        );

    setState(() {
      _suggestion = null;
      _searchError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createRequestProvider).draft;
    final hasAddress = (draft.formattedAddress ?? '').trim().isNotEmpty;
    final hasRealCoords = draft.locationLatitude != null &&
        draft.locationLongitude != null &&
        draft.locationLatitude != 0 &&
        draft.locationLongitude != 0;

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
          Text(
            l10n.createRequestStep2Heading,
            style: AppTypography.h3.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm - 4),
          Text(
            l10n.createRequestStep2Subheading,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),

          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLocating ? null : _useCurrentLocation,
              icon: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 20),
              label: Text(l10n.createRequestStep2UseCurrentLocation),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: const StadiumBorder(),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.borderLight)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  l10n.createRequestStep2Or,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.borderLight)),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: AppColors.borderLight, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    onChanged: _onAddressChanged,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.createRequestStep2SearchHint,
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_isGeocoding)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (hasAddress)
                  GestureDetector(
                    onTap: () {
                      _addressController.clear();
                      _onAddressChanged('');
                    },
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),

          if (_suggestion != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _SuggestionCard(
              suggestion: _suggestion!,
              onUse: _acceptSuggestion,
              onDismiss: () => setState(() => _suggestion = null),
            ),
          ],

          if (_searchError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _searchError!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          if (hasAddress)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: AppRadii.borderLg,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cream.withValues(alpha: 0.7),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasRealCoords
                              ? l10n.createRequestStep2ConfirmedTitle
                              : l10n.createRequestStep2ApproximateTitle,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          draft.formattedAddress ?? '',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.onUse,
    required this.onDismiss,
  });

  final GeoPoint suggestion;
  final VoidCallback onUse;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.4),
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  suggestion.label ?? '',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
              const SizedBox(width: AppSpacing.xs),
              ElevatedButton(
                onPressed: onUse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.textInverse,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Use this address'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}