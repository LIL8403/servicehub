import 'package:flutter/foundation.dart';

@immutable
class VerificationStatus {
  const VerificationStatus({
    required this.status,
    required this.sections,
    this.legalName,
    this.dateOfBirth,
    this.residentialAddress,
    this.identityDocument,
    this.selfie,
    this.supportingDocuments = const [],
    this.submittedAt,
    this.rejectionReason,
    this.history = const [],
  });

  final String status;
  final VerificationSections sections;

  final String? legalName;
  final String? dateOfBirth;
  final String? residentialAddress;
  final Map<String, dynamic>? identityDocument;
  final Map<String, dynamic>? selfie;
  final List<Map<String, dynamic>> supportingDocuments;

  final DateTime? submittedAt;
  final String? rejectionReason;
  final List<Map<String, dynamic>> history;

  bool get isEditable => status == 'unverified' || status == 'rejected';
  bool get isPending => status == 'pending';
  bool get isVerified => status == 'verified';
  bool get isRejected => status == 'rejected';
  bool get isUnverified => status == 'unverified';

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    final sectionsJson = (json['sections'] as Map<String, dynamic>?) ?? {};
    final supports = (json['supporting_documents'] as List?) ?? const [];

    return VerificationStatus(
      status: json['status']?.toString() ?? 'unverified',
      sections: VerificationSections.fromJson(sectionsJson),
      legalName: json['legal_name']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      residentialAddress: json['residential_address']?.toString(),
      identityDocument: json['identity_document'] as Map<String, dynamic>?,
      selfie: json['selfie'] as Map<String, dynamic>?,
      supportingDocuments: supports
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
      submittedAt: _parseDate(json['submitted_at']),
      rejectionReason: json['rejection_reason']?.toString(),
      history: ((json['history'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

@immutable
@immutable
class VerificationSections {
  const VerificationSections({
    required this.identityComplete,
    required this.professionalComplete,
    required this.supportingComplete,
    this.supportingCount = 0,
  });

  final bool identityComplete;
  final bool professionalComplete;
  final bool supportingComplete;

  /// Number of supporting documents the artisan has uploaded.
  /// Zero when none have been added — the section is optional and
  /// does not block submission, but we display its state honestly.
  final int supportingCount;

  factory VerificationSections.fromJson(Map<String, dynamic> json) {
    final supporting = json['supporting'] as Map<String, dynamic>?;
    return VerificationSections(
      identityComplete:
          (json['identity'] as Map<String, dynamic>?)?['complete'] == true,
      professionalComplete:
          (json['professional'] as Map<String, dynamic>?)?['complete'] == true,
      supportingComplete: supporting?['complete'] == true,
      supportingCount: (supporting?['count'] as num?)?.toInt() ?? 0,
    );
  }
}