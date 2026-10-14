import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_radii.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/availability.dart';
import '../providers/artisan_profile_providers.dart';
import '../widgets/availability/day_schedule_row.dart';
import '../widgets/availability/service_areas_editor.dart';

class ArtisanAvailabilityPage extends ConsumerStatefulWidget {
  const ArtisanAvailabilityPage({super.key});

  @override
  ConsumerState<ArtisanAvailabilityPage> createState() =>
      _ArtisanAvailabilityPageState();
}

class _ArtisanAvailabilityPageState
    extends ConsumerState<ArtisanAvailabilityPage> {
  Availability? _availability;
  List<String> _cities = [];
  bool _hydrated = false;
  String? _errorMessage;

  // Snapshots for dirty-checking.
  Availability? _loadedAvailability;
  List<String> _loadedCities = [];

  void _hydrateFrom(Map<String, dynamic> profile) {
    if (_hydrated) return;
    _hydrated = true;

    final availability = Availability.fromJson(
      profile['availability'] as Map<String, dynamic>?,
    );

    final rawAreas = (profile['service_areas'] as List?) ?? const [];
    final cities = <String>[];
    for (final entry in rawAreas) {
      // Tolerate either the new shape (String) or the legacy shape
      // ({city, radius_km}) in case the migration hasn't run.
      if (entry is String && entry.isNotEmpty) {
        cities.add(entry);
      } else if (entry is Map<String, dynamic>) {
        final city = entry['city']?.toString() ?? '';
        if (city.isNotEmpty) cities.add(city);
      }
    }

    _availability = availability;
    _loadedAvailability = availability;
    _cities = cities;
    _loadedCities = List<String>.from(cities);

    if (mounted) setState(() {});
  }

  bool get _hasChanges {
    final a = _availability;
    final b = _loadedAvailability;
    if (a == null || b == null) return false;

    if (a.acceptingRequests != b.acceptingRequests) return true;
    if (a.radiusKm != b.radiusKm) return true;
    for (final day in Availability.weekdayKeys) {
      final x = a.days[day] ?? const [];
      final y = b.days[day] ?? const [];
      if (x.length != y.length) return true;
      for (var i = 0; i < x.length; i++) {
        if (x[i].start != y[i].start || x[i].end != y[i].end) return true;
      }
    }

    if (_cities.length != _loadedCities.length) return true;
    final set = _loadedCities.toSet();
    for (final c in _cities) {
      if (!set.contains(c)) return true;
    }

    return false;
  }

  Future<void> _save() async {
    final a = _availability;
    if (a == null) return;

    if (_cities.isEmpty) {
      setState(
        () => _errorMessage = 'Pick at least one city where you take jobs.',
      );
      return;
    }

    setState(() => _errorMessage = null);

    final payload = <String, dynamic>{
      'availability': a.toJson(),
      'service_areas': _cities,
    };

    final ok = await ref
        .read(artisanProfileActionProvider.notifier)
        .save(payload);

    if (!mounted) return;

    if (ok) {
      ref.invalidate(artisanProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability updated.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      setState(() {
        _errorMessage =
            ref.read(artisanProfileActionProvider).errorMessage ??
            'Could not save your availability.';
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  // Mutations
  // ─────────────────────────────────────────────────────────

  void _setAccepting(bool value) {
    setState(() {
      _availability = _availability!.copyWith(acceptingRequests: value);
    });
  }

  void _setRadius(int value) {
    setState(() {
      _availability = _availability!.copyWith(radiusKm: value);
    });
  }

  void _toggleDay(String day, bool enabled) {
    setState(() {
      final days = Map<String, List<Shift>>.from(_availability!.days);
      days[day] = enabled
          ? const [Shift(start: '08:00', end: '18:00')]
          : const [];
      _availability = _availability!.copyWith(days: days);
    });
  }

  void _changeShift(String day, int index, Shift shift) {
    setState(() {
      final days = Map<String, List<Shift>>.from(_availability!.days);
      final list = List<Shift>.from(days[day] ?? const []);
      if (index < 0 || index >= list.length) return;
      list[index] = shift;
      days[day] = list;
      _availability = _availability!.copyWith(days: days);
    });
  }

  void _removeShift(String day, int index) {
    setState(() {
      final days = Map<String, List<Shift>>.from(_availability!.days);
      final list = List<Shift>.from(days[day] ?? const []);
      if (index < 0 || index >= list.length) return;
      list.removeAt(index);
      days[day] = list;
      _availability = _availability!.copyWith(days: days);
    });
  }

  void _addShift(String day) {
    setState(() {
      final days = Map<String, List<Shift>>.from(_availability!.days);
      final list = List<Shift>.from(days[day] ?? const []);
      // Anchor the new window after the last one if there's room,
      // otherwise default to the morning.
      final last = list.isNotEmpty ? list.last : null;
      final next = last != null && last.end != '23:59'
          ? Shift(start: last.end, end: _addTwoHours(last.end))
          : const Shift(start: '14:00', end: '18:00');
      list.add(next);
      days[day] = list;
      _availability = _availability!.copyWith(days: days);
    });
  }

  String _addTwoHours(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 8;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final total = h * 60 + m + 120;
    final nh = (total ~/ 60).clamp(0, 23).toString().padLeft(2, '0');
    final nm = (total % 60).toString().padLeft(2, '0');
    return '$nh:$nm';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(artisanProfileProvider, (_, next) {
      next.whenData(_hydrateFrom);
    });
    final initial = ref.read(artisanProfileProvider);
    initial.whenData(_hydrateFrom);

    final action = ref.watch(artisanProfileActionProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Availability',
          style: AppTypography.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: initial.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(artisanProfileProvider),
        ),
        data: (_) {
          final a = _availability;
          if (a == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _acceptingCard(a),
                      const SizedBox(height: AppSpacing.md),
                      _radiusCard(a),
                      const SizedBox(height: AppSpacing.md),
                      _weeklyCard(a),
                      const SizedBox(height: AppSpacing.md),
                      _serviceAreasCard(),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _errorBanner(_errorMessage!),
                      ],
                    ],
                  ),
                ),
              ),
              _bottomActions(
                enabled: _hasChanges && !action.isSaving,
                isSaving: action.isSaving,
                onSave: _save,
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Cards
  // ─────────────────────────────────────────────────────────

  Widget _acceptingCard(Availability a) {
    return _SectionCard(
      label: 'ACCEPTING REQUESTS',
      child: Row(
        children: [
          Expanded(
            child: Text(
              a.acceptingRequests
                  ? 'You are visible to customers and can receive new requests.'
                  : 'You are hidden from search. Existing jobs are unaffected.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          Switch.adaptive(
            value: a.acceptingRequests,
            onChanged: _setAccepting,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
            inactiveThumbColor: AppColors.cardLight,
            inactiveTrackColor: AppColors.borderLight,
          ),
        ],
      ),
    );
  }

  Widget _radiusCard(Availability a) {
    const options = [5, 10, 15, 20, 25, 50];

    return _SectionCard(
      label: 'SERVICE RADIUS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How far from your base you are willing to travel for a job.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final km in options)
                _RadiusChip(
                  km: km,
                  selected: a.radiusKm == km,
                  onTap: () => _setRadius(km),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weeklyCard(Availability a) {
    return _SectionCard(
      label: 'WEEKLY SCHEDULE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Turn each day on and set your working windows.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final day in Availability.weekdayKeys)
            DayScheduleRow(
              day: day,
              label: Availability.weekdayLabels[day] ?? day,
              shifts: a.days[day] ?? const [],
              onToggleDay: (enabled) => _toggleDay(day, enabled),
              onShiftChanged: (i, s) => _changeShift(day, i, s),
              onShiftRemoved: (i) => _removeShift(day, i),
              onShiftAdded: () => _addShift(day),
            ),
        ],
      ),
    );
  }

  Widget _serviceAreasCard() {
    return _SectionCard(
      label: 'SERVICE AREAS',
      child: ServiceAreasEditor(
        selected: _cities,
        onChanged: (list) => setState(() => _cities = list),
      ),
    );
  }

  Widget _bottomActions({
    required bool enabled,
    required bool isSaving,
    required VoidCallback onSave,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardLight,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? onSave : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textInverse,
            disabledBackgroundColor: AppColors.disabledBg,
            disabledForegroundColor: AppColors.disabledText,
            shape: const StadiumBorder(),
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
                  enabled ? 'Save changes' : 'No changes to save',
                  style: AppTypography.bodyLarge.copyWith(
                    color: enabled
                        ? AppColors.textInverse
                        : AppColors.disabledText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.errorTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          child,
        ],
      ),
    );
  }
}

class _RadiusChip extends StatelessWidget {
  const _RadiusChip({
    required this.km,
    required this.selected,
    required this.onTap,
  });

  final int km;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardLight,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Text(
          '$km km',
          style: AppTypography.bodySmall.copyWith(
            color: selected ? AppColors.textInverse : AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
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
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
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
