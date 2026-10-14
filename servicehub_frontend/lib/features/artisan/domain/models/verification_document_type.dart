import 'package:flutter/foundation.dart';

@immutable
class VerificationDocumentType {
  const VerificationDocumentType({
    required this.key,
    required this.label,
    this.description,
    this.requiresBack = false,
    this.hasExpiry = false,
  });

  final String key;
  final String label;
  final String? description;
  final bool requiresBack;
  final bool hasExpiry;

  factory VerificationDocumentType.fromJson(Map<String, dynamic> json) {
    return VerificationDocumentType(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      description: json['description']?.toString(),
      requiresBack: json['requires_back'] == true,
      hasExpiry: json['has_expiry'] == true,
    );
  }
}

@immutable
class VerificationConfig {
  const VerificationConfig({
    required this.identityDocumentTypes,
    required this.supportingDocumentTypes,
    required this.maxSupportingDocuments,
    required this.maxFileSizeKb,
  });

  final List<VerificationDocumentType> identityDocumentTypes;
  final List<VerificationDocumentType> supportingDocumentTypes;
  final int maxSupportingDocuments;
  final int maxFileSizeKb;

  factory VerificationConfig.fromJson(Map<String, dynamic> json) {
    final ids = (json['identity_document_types'] as List?) ?? const [];
    final supports = (json['supporting_document_types'] as List?) ?? const [];

    return VerificationConfig(
      identityDocumentTypes: ids
          .whereType<Map<String, dynamic>>()
          .map(VerificationDocumentType.fromJson)
          .toList(),
      supportingDocumentTypes: supports
          .whereType<Map<String, dynamic>>()
          .map(VerificationDocumentType.fromJson)
          .toList(),
      maxSupportingDocuments:
          (json['max_supporting_documents'] as num?)?.toInt() ?? 8,
      maxFileSizeKb: (json['max_file_size_kb'] as num?)?.toInt() ?? 5120,
    );
  }
}