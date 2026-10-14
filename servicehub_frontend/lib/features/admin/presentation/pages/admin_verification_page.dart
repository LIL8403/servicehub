import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../data/repositories/admin_verification_repository.dart';
import '../providers/admin_verification_providers.dart';
import '../widgets/verification/reject_reason_dialog.dart';
import '../widgets/verification/verification_detail_header.dart';
import '../widgets/verification/verification_document_row.dart';
import '../widgets/verification/verification_empty_queue.dart';
import '../widgets/verification/verification_image_tile.dart';
import '../widgets/verification/verification_label_value_row.dart';
import '../widgets/verification/verification_queue_item.dart';
import '../widgets/verification/verification_section_anchor_nav.dart';
import '../widgets/verification/verification_section_card.dart';

class AdminVerificationPage extends ConsumerStatefulWidget {
  const AdminVerificationPage({super.key});

  @override
  ConsumerState<AdminVerificationPage> createState() =>
      _AdminVerificationPageState();
}

class _AdminVerificationPageState extends ConsumerState<AdminVerificationPage> {
  final _searchController = TextEditingController();
  final _detailScrollController = ScrollController();

  String _filter = 'all'; // all | cni | passport | today
  String _activeAnchor = 'identity';

  // Keyed scroll targets inside the detail panel.
  final _sectionKeys = <String, GlobalKey>{
    'identity': GlobalKey(),
    'id-document': GlobalKey(),
    'selfie': GlobalKey(),
    'professional': GlobalKey(),
    'documents': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _detailScrollController.addListener(_onDetailScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _detailScrollController.dispose();
    super.dispose();
  }

  void _onDetailScroll() {
    if (!_detailScrollController.hasClients) return;

    final ancestorRenderObject = context.findRenderObject();
    if (ancestorRenderObject == null) return;

    String? current;
    double? currentOffset;
    for (final entry in _sectionKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final offset = box
          .localToGlobal(Offset.zero, ancestor: ancestorRenderObject)
          .dy;
      if (offset <= 200 && (currentOffset == null || offset > currentOffset)) {
        current = entry.key;
        currentOffset = offset;
      }
    }

    // If we're at or near the bottom of the scroll, force the last
    // anchor to be active. This ensures "Documents" (the final section)
    // gets highlighted when scrolled to its end.
    final position = _detailScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 8) {
      current = _sectionKeys.keys.last;
    }

    if (current != null && current != _activeAnchor) {
      setState(() => _activeAnchor = current!);
    }
  }

  void _jumpToAnchor(String key) {
    final ctx = _sectionKeys[key]?.currentContext;
    if (ctx == null) return;
    setState(() => _activeAnchor = key);
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: 0.0,
    );
  }

  List<PendingArtisan> _applyFilters(List<PendingArtisan> all) {
    final query = _searchController.text.trim().toLowerCase();
    return all
        .where((a) {
          if (query.isNotEmpty) {
            final matchesName = a.fullName.toLowerCase().contains(query);
            final matchesEmail = a.email.toLowerCase().contains(query);
            if (!matchesName && !matchesEmail) return false;
          }
          switch (_filter) {
            case 'cni':
              final type = a.identityDocument?['type']?.toString();
              if (type != 'cni') return false;
              break;
            case 'passport':
              final type = a.identityDocument?['type']?.toString();
              if (type != 'passport') return false;
              break;
            case 'today':
              final submitted = a.submittedAt;
              if (submitted == null) return false;
              final now = DateTime.now();
              if (now.difference(submitted).inHours >= 24) return false;
              break;
            default:
              break;
          }
          return true;
        })
        .toList(growable: false);
  }

  Future<void> _onApprove(PendingArtisan artisan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Approve application?',
          style: AppTypography.h4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          '${artisan.fullName} will be marked as a verified artisan '
          'and can start accepting requests.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Approve',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await ref
        .read(adminVerificationActionProvider.notifier)
        .approve(artisan.id);

    if (!mounted) return;

    if (ok) {
      ref.read(selectedArtisanProvider.notifier).state = null;
      _showSnack('${artisan.fullName} approved.', success: true);
    } else {
      final err = ref.read(adminVerificationActionProvider).errorMessage;
      _showSnack(err ?? 'Could not approve.', success: false);
    }
  }

  Future<void> _onReject(PendingArtisan artisan) async {
    final reason = await showRejectReasonDialog(
      context,
      artisanName: artisan.fullName,
    );
    if (reason == null || !mounted) return;

    final ok = await ref
        .read(adminVerificationActionProvider.notifier)
        .reject(artisan.id, reason);

    if (!mounted) return;

    if (ok) {
      ref.read(selectedArtisanProvider.notifier).state = null;
      _showSnack('${artisan.fullName} rejected.', success: false);
    } else {
      final err = ref.read(adminVerificationActionProvider).errorMessage;
      _showSnack(err ?? 'Could not reject.', success: false);
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

  Future<void> _viewImage({
    required PendingArtisan artisan,
    required String slot,
    required String title,
  }) async {
    final repo = ref.read(adminVerificationRepositoryProvider);
    try {
      final result = await repo.downloadDocument(
        artisanId: artisan.id,
        slot: slot,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.cardLight,
          insetPadding: const EdgeInsets.all(40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.h4.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderLight,
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: Image.memory(
                        Uint8List.fromList(result.bytes),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: Text(
                            'This document could not be displayed.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not load document: $e', success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(pendingArtisansProvider);
    final action = ref.watch(adminVerificationActionProvider);
    final selected = ref.watch(selectedArtisanProvider);

    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorView(
        message: err.toString(),
        onRetry: () => ref.invalidate(pendingArtisansProvider),
      ),
      data: (all) {
        final filtered = _applyFilters(all);

        // Auto-select first item if nothing is selected or the current
        // selection no longer exists.
        if (selected == null || !all.any((a) => a.id == selected.id)) {
          if (filtered.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.read(selectedArtisanProvider.notifier).state =
                    filtered.first;
              }
            });
          }
        }

        final current =
            selected != null && filtered.any((a) => a.id == selected.id)
            ? selected
            : (filtered.isNotEmpty ? filtered.first : null);

        return Row(
          children: [
            _queuePanel(all, filtered, current),
            Expanded(
              child: current == null
                  ? const VerificationEmptyQueue()
                  : _detailPanel(current, action),
            ),
          ],
        );
      },
    );
  }

  Widget _queuePanel(
    List<PendingArtisan> all,
    List<PendingArtisan> filtered,
    PendingArtisan? current,
  ) {
    return Container(
      width: 400,
      decoration: const BoxDecoration(
        color: AppColors.cardLight,
        border: Border(right: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        children: [
          _queueHeader(all.length),
          _searchBar(),
          _filterRow(),
          const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
          Expanded(
            child: filtered.isEmpty
                ? const VerificationEmptyQueue()
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.borderLight,
                    ),
                    itemBuilder: (_, i) {
                      final a = filtered[i];
                      return VerificationQueueItem(
                        artisan: a,
                        selected: current?.id == a.id,
                        onTap: () {
                          ref.read(selectedArtisanProvider.notifier).state = a;
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _queueHeader(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Artisan verification',
            style: AppTypography.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$total pending application${total == 1 ? '' : 's'}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Search by name or email...',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          _filterChip('all', 'All'),
          const SizedBox(width: 8),
          _filterChip('cni', 'CNI'),
          const SizedBox(width: 8),
          _filterChip('passport', 'Passport'),
          const SizedBox(width: 8),
          _filterChip('today', 'Today'),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final active = _filter == key;
    return Material(
      color: active ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        borderRadius: BorderRadius.circular(9999),
        onTap: () => setState(() => _filter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.borderLight,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: active ? Colors.white : AppColors.textMuted,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailPanel(
    PendingArtisan artisan,
    AdminVerificationActionState action,
  ) {
    final busy = action.inFlightId == artisan.id;

    return Column(
      children: [
        VerificationDetailHeader(
          artisan: artisan,
          busy: busy,
          onApprove: () => _onApprove(artisan),
          onReject: () => _onReject(artisan),
        ),
        VerificationSectionAnchorNav(
          activeKey: _activeAnchor,
          onSelect: _jumpToAnchor,
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _detailScrollController,
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _identitySection(artisan),
                const SizedBox(height: 24),
                _idDocumentSection(artisan),
                const SizedBox(height: 24),
                _selfieSection(artisan),
                const SizedBox(height: 24),
                _professionalSection(artisan),
                const SizedBox(height: 24),
                _documentsSection(artisan),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _identitySection(PendingArtisan artisan) {
    return KeyedSubtree(
      key: _sectionKeys['identity'],
      child: VerificationSectionCard(
        icon: Icons.person_outline,
        title: 'Identity',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VerificationLabelValueRow(
              label: 'Legal name',
              value: artisan.legalName ?? '—',
            ),
            const SizedBox(height: 12),
            VerificationLabelValueRow(
              label: 'Date of birth',
              value: _formatDob(artisan.dateOfBirth),
            ),
            const SizedBox(height: 12),
            VerificationLabelValueRow(
              label: 'Residential address',
              value: artisan.residentialAddress ?? '—',
            ),
            const SizedBox(height: 12),
            VerificationLabelValueRow(
              label: 'Phone',
              value: artisan.phone.isEmpty ? '—' : artisan.phone,
            ),
            const SizedBox(height: 12),
            VerificationLabelValueRow(
              label: 'Email',
              value: artisan.email.isEmpty ? '—' : artisan.email,
            ),
          ],
        ),
      ),
    );
  }

  Widget _idDocumentSection(PendingArtisan artisan) {
    final doc = artisan.identityDocument;
    final type = doc?['type']?.toString();
    final typeLabel = type == 'passport'
        ? 'Passport'
        : type == 'cni'
        ? 'National Identity Card (CNI)'
        : '—';
    final number = doc?['number']?.toString() ?? '—';
    final expiresAt = doc?['expires_at']?.toString();
    final frontName = (doc?['front'] as Map<String, dynamic>?)?['name']
        ?.toString();
    final backName = (doc?['back'] as Map<String, dynamic>?)?['name']
        ?.toString();

    return KeyedSubtree(
      key: _sectionKeys['id-document'],
      child: VerificationSectionCard(
        icon: Icons.badge_outlined,
        title: 'Identity document',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VerificationLabelValueRow(label: 'Document type', value: typeLabel),
            const SizedBox(height: 12),
            VerificationLabelValueRow(label: 'Document number', value: number),
            const SizedBox(height: 12),
            VerificationLabelValueRow(
              label: 'Expires',
              value: expiresAt == null || expiresAt.isEmpty
                  ? '—'
                  : _formatDate(expiresAt),
            ),
            const SizedBox(height: 24),
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderLight,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                VerificationImageTile(
                  label: 'Front',
                  width: 260,
                  height: 160,
                  hasImage: artisan.hasIdentityDocument,
                  filename: frontName,
                  onTap: () => _viewImage(
                    artisan: artisan,
                    slot: 'identity-front',
                    title: 'ID document — front',
                  ),
                ),
                VerificationImageTile(
                  label: 'Back',
                  width: 260,
                  height: 160,
                  hasImage:
                      (doc?['back'] as Map<String, dynamic>?)?['path'] != null,
                  filename: backName,
                  onTap: () => _viewImage(
                    artisan: artisan,
                    slot: 'identity-back',
                    title: 'ID document — back',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _selfieSection(PendingArtisan artisan) {
    final selfieName = artisan.selfie?['name']?.toString();
    return KeyedSubtree(
      key: _sectionKeys['selfie'],
      child: VerificationSectionCard(
        icon: Icons.face_outlined,
        title: 'Verification selfie',
        child: Column(
          children: [
            VerificationImageTile(
              label: 'Selfie',
              width: 200,
              height: 200,
              hasImage: artisan.hasSelfie,
              filename: selfieName,
              onTap: () => _viewImage(
                artisan: artisan,
                slot: 'selfie',
                title: 'Verification selfie',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Captured during submission. Compare with the ID '
              'document photo.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _professionalSection(PendingArtisan artisan) {
    final raw = artisan.raw;
    final experience = raw['experience_years'];
    final languages =
        (raw['languages'] as List?)?.whereType<String>().toList(
          growable: false,
        ) ??
        const <String>[];
    final serviceAreas =
        (raw['service_areas'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((area) {
              final city = area['city']?.toString() ?? '';
              final radius = area['radius_km'];
              if (city.isEmpty) return '';
              if (radius != null) return '$city ($radius km)';
              return city;
            })
            .where((s) => s.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    final offerings =
        (raw['service_offerings'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];

    final about =
        raw['professional_description']?.toString() ??
        raw['bio']?.toString() ??
        '';

    return KeyedSubtree(
      key: _sectionKeys['professional'],
      child: VerificationSectionCard(
        icon: Icons.work_outline,
        title: 'Professional profile',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VerificationLabelValueRow(
              label: 'Title',
              value: artisan.professionalTitle.isEmpty
                  ? '—'
                  : artisan.professionalTitle,
            ),
            const SizedBox(height: 14),
            VerificationLabelValueRow(
              label: 'Experience',
              value: experience != null ? '$experience years' : '—',
            ),
            const SizedBox(height: 14),
            VerificationLabelValueRow(
              label: 'Services offered',
              valueWidget: offerings.isEmpty
                  ? Text(
                      '—',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in offerings)
                          _serviceChip(o['service_reference']?.toString()),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            VerificationLabelValueRow(
              label: 'Languages',
              value: languages.isEmpty
                  ? '—'
                  : languages.map(_titleCase).join(', '),
            ),
            const SizedBox(height: 14),
            VerificationLabelValueRow(
              label: 'Service areas',
              value: serviceAreas.isEmpty ? '—' : serviceAreas.join(', '),
            ),
            if (about.isNotEmpty) ...[
              const SizedBox(height: 14),
              VerificationLabelValueRow(label: 'About', value: about),
            ],
          ],
        ),
      ),
    );
  }

  Widget _serviceChip(String? ref) {
    final label = ref == null || ref.isEmpty
        ? 'Service'
        : 'Service ${ref.substring(0, ref.length > 6 ? 6 : ref.length)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _documentsSection(PendingArtisan artisan) {
    final docs = artisan.supportingDocuments;
    return KeyedSubtree(
      key: _sectionKeys['documents'],
      child: VerificationSectionCard(
        icon: Icons.folder_open_outlined,
        title: 'Supporting documents',
        trailing: Text(
          '${docs.length} attached file${docs.length == 1 ? '' : 's'}',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
        child: docs.isEmpty
            ? _emptyDocuments()
            : Column(
                children: [
                  for (var i = 0; i < docs.length; i++) ...[
                    VerificationDocumentRow(
                      label: docs[i]['label']?.toString() ?? 'Document',
                      sizeLabel: _fileSizeLabel(docs[i]),
                      onView: () {
                        final id = docs[i]['id']?.toString() ?? '';
                        if (id.isEmpty) return;
                        _viewImage(
                          artisan: artisan,
                          slot: 'document:$id',
                          title: docs[i]['label']?.toString() ?? 'Document',
                        );
                      },
                    ),
                    if (i < docs.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.borderLight,
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _emptyDocuments() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 40,
            color: AppColors.textMuted.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'No supporting documents',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This artisan did not upload any optional documents.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _fileSizeLabel(Map<String, dynamic> doc) {
    final file = doc['file'];
    if (file is Map<String, dynamic>) {
      final size = file['size'];
      if (size is num) {
        final bytes = size.toInt();
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1024 * 1024) {
          return '${(bytes / 1024).round()} KB';
        }
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }
    return 'Size unknown';
  }

  String _formatDob(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final now = DateTime.now();
    var age = now.year - parsed.year;
    if (now.month < parsed.month ||
        (now.month == parsed.month && now.day < parsed.day)) {
      age--;
    }
    return '${_formatDate(iso)} ($age years old)';
  }

  String _formatDate(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  String _titleCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
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
