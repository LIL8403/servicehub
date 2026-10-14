import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../ui/core/theme/app_colors.dart';
import '../../../../ui/core/theme/app_spacing.dart';
import '../../../../ui/core/theme/app_typography.dart';
import '../../domain/models/verification_document_type.dart';
import '../providers/artisan_verification_providers.dart';
import '../widgets/verification/add_document_type_sheet.dart';
import '../widgets/verification/supporting_document_card.dart';
import '../widgets/verification/verification_step_indicator.dart';
import '../widgets/verification/rejection_card.dart';

class ArtisanSupportingDocumentsPage extends ConsumerStatefulWidget {
  const ArtisanSupportingDocumentsPage({super.key});

  @override
  ConsumerState<ArtisanSupportingDocumentsPage> createState() =>
      _ArtisanSupportingDocumentsPageState();
}

class _ArtisanSupportingDocumentsPageState
    extends ConsumerState<ArtisanSupportingDocumentsPage> {
  final _picker = ImagePicker();

  /// Set of document IDs currently being uploaded, keyed by local
  /// temp file so we can render an in-progress card.
  final _uploading = <String, _UploadingDoc>{};

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(artisanVerificationProvider);
    final action = ref.watch(verificationActionProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: _buildAppBar(context),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(artisanVerificationProvider),
        ),
        data: (snapshot) {
          final status = snapshot.status;
          final types = snapshot.config.supportingDocumentTypes;
          final documents = status.supportingDocuments;
          final maxDocs = snapshot.config.maxSupportingDocuments;
          final canAddMore =
              documents.length + _uploading.length < maxDocs;

          return Column(
            children: [
              const VerificationStepIndicator(
                activeStep: 2,
                completedSteps: {0, 1},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (status.isRejected &&
                          (status.rejectionReason?.isNotEmpty ?? false)) ...[
                        RejectionCard(reason: status.rejectionReason!),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _introCard(),
                      const SizedBox(height: AppSpacing.md),
                      if (documents.isEmpty && _uploading.isEmpty)
                        _emptyState()
                      else
                        _documentsList(documents),
                      const SizedBox(height: AppSpacing.md),
                      if (canAddMore)
                        _addButton(types),
                      const SizedBox(height: AppSpacing.sm),
                      _limitHelper(maxDocs),
                      const SizedBox(height: AppSpacing.md),
                      _infoCallout(),
                      if (action.errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _errorBanner(action.errorMessage!),
                      ],
                    ],
                  ),
                ),
              ),
              _bottomActions(documents.isNotEmpty || _uploading.isNotEmpty),
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
          Flexible(
            child: Text(
              'Supporting documents',
              style: AppTypography.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
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
                  Icons.folder_open_outlined,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Text(
                  'Supporting documents',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'OPTIONAL',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            'Add certificates, trade qualifications, or business '
            'registration if you have them. These strengthen your '
            'application but are not required.',
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

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 32,
      ),
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
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.folder_open_outlined,
              size: 28,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          Text(
            'No documents yet',
            style: AppTypography.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 240,
            child: Text(
              'Supporting documents are optional.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentsList(List<Map<String, dynamic>> documents) {
    return Column(
      children: [
        for (final entry in _uploading.values) ...[
          _uploadingCard(entry),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (var i = 0; i < documents.length; i++) ...[
          SupportingDocumentCard(
            label: documents[i]['label']?.toString() ?? 'Document',
            uploadedAt: _parseDate(documents[i]['uploaded_at']),
            fileSize: _parseFileSize(documents[i]),
            onView: () => _viewDocument(documents[i]),
            onRemove: () => _removeDocument(documents[i]),
          ),
          if (i < documents.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _uploadingCard(_UploadingDoc doc) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.secondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uploading...',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doc.filename,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 20,
              color: AppColors.error,
            ),
            onPressed: null, // Upload cancellation is a polish item.
          ),
        ],
      ),
    );
  }

  Widget _addButton(List<VerificationDocumentType> types) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pickAndUpload(types),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.5),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add,
                size: 24,
                color: AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Add supporting document',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _limitHelper(int maxDocs) {
    return Text(
      'Up to $maxDocs documents · Images only · Max 5 MB each',
      textAlign: TextAlign.center,
      style: AppTypography.caption.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
        fontSize: 11,
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
              'These documents are stored securely and only seen by '
              'our verification team.',
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
          const Icon(Icons.error_outline, size: 20, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
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

  Widget _bottomActions(bool hasDocuments) {
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
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasDocuments
                    ? AppColors.primary
                    : const Color(0xFFF1F5F9),
                foregroundColor: hasDocuments
                    ? AppColors.textInverse
                    : AppColors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                hasDocuments ? 'Done' : 'Skip for now',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: hasDocuments
                      ? AppColors.textInverse
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          if (hasDocuments) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Skip for now',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(
    List<VerificationDocumentType> types,
  ) async {
    if (types.isEmpty) return;

    final selected = await showAddDocumentTypeSheet(
      context,
      types: types,
    );
    if (selected == null || !mounted) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2400,
    );
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    final tempId = DateTime.now().microsecondsSinceEpoch.toString();

    setState(() {
      _uploading[tempId] = _UploadingDoc(
        filename: picked.name,
        label: selected.label,
      );
    });

    final ok = await ref
        .read(verificationActionProvider.notifier)
        .uploadSupportingDocument(
          documentType: selected.key,
          label: selected.label,
          document: file,
        );

    if (!mounted) return;

    setState(() => _uploading.remove(tempId));

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selected.label} uploaded.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removeDocument(Map<String, dynamic> document) async {
    final id = document['id']?.toString();
    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove document?'),
        content: Text(
          'This will remove ${document['label'] ?? 'this document'}. '
          'You can upload it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await ref
        .read(verificationActionProvider.notifier)
        .deleteSupportingDocument(id);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document removed.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _viewDocument(Map<String, dynamic> document) async {
    final id = document['id']?.toString();
    if (id == null || id.isEmpty) return;

    // Preview comes as a polish item; for now show the download
    // result in a snackbar so the flow is wired end-to-end.
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview coming soon.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // When ready:
      // final result = await ref
      //     .read(artisanVerificationRepositoryProvider)
      //     .downloadSupportingDocument(id);
      // // open result.bytes in a preview sheet or full-screen viewer
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open document.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  int _parseFileSize(Map<String, dynamic> doc) {
    final file = doc['file'];
    if (file is Map<String, dynamic>) {
      final size = file['size'];
      if (size is num) return size.toInt();
    }
    return 0;
  }
}

class _UploadingDoc {
  const _UploadingDoc({required this.filename, required this.label});
  final String filename;
  final String label;
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