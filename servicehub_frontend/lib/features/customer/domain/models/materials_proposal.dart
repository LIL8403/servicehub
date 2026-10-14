import 'package:flutter/foundation.dart';

/// A single line item in a materials proposal.
///
/// The backend stores these under `service_requests.materials` as an
/// array. Every item in the array belongs to the same proposal
/// version — the artisan can resubmit, which increments the version
/// and replaces the array wholesale.
@immutable
class MaterialItem {
  const MaterialItem({
    required this.name,
    required this.quantity,
    required this.unitCost,
    required this.estimatedCost,
    required this.proposalVersion,
    required this.approvalStatus,
  });

  final String name;
  final double quantity;
  final double unitCost;
  final double estimatedCost;
  final int proposalVersion;
  final String approvalStatus;

  bool get isProposed => approvalStatus == 'proposed';
  bool get isApproved => approvalStatus == 'approved';

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      name: json['name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0,
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0,
      proposalVersion: (json['proposal_version'] as num?)?.toInt() ?? 1,
      approvalStatus: json['approval_status']?.toString() ?? 'proposed',
    );
  }
}

/// Wrapper over a list of [MaterialItem]s for convenience.
@immutable
class MaterialsProposal {
  const MaterialsProposal({required this.items});

  final List<MaterialItem> items;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// True when every item is in `proposed` state — the artisan has
  /// submitted and the customer hasn't approved or rejected.
  bool get isPendingApproval =>
      items.isNotEmpty && items.every((i) => i.isProposed);

  /// True when every item is `approved`.
  bool get isApproved =>
      items.isNotEmpty && items.every((i) => i.isApproved);

  /// Total the customer would approve.
  double get estimatedTotal =>
      items.fold(0.0, (sum, i) => sum + i.estimatedCost);

  int get proposalVersion => items.isEmpty ? 0 : items.first.proposalVersion;

  static MaterialsProposal fromJsonList(dynamic raw) {
    if (raw is! List) return const MaterialsProposal(items: []);
    return MaterialsProposal(
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(MaterialItem.fromJson)
          .toList(growable: false),
    );
  }
}