import 'package:flutter/foundation.dart';

@immutable
class EarningsSummary {
  const EarningsSummary({
    required this.pending,
    required this.paid,
    required this.failed,
    required this.currency,
    required this.payoutPhoneConfigured,
    required this.commissionRate,
    required this.lifetimeGross,
    required this.lifetimeNet,
    required this.lifetimeCommission,
  });

  final int pending;
  final int paid;
  final int failed;
  final String currency;
  final bool payoutPhoneConfigured;
  final double commissionRate;
  final int lifetimeGross;
  final int lifetimeNet;
  final int lifetimeCommission;

  int get lifetime => paid + pending;

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      paid: (json['paid'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'XAF',
      payoutPhoneConfigured: json['payout_phone_configured'] == true,
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.0,
      lifetimeGross: (json['lifetime_gross'] as num?)?.toInt() ?? 0,
      lifetimeNet: (json['lifetime_net'] as num?)?.toInt() ?? 0,
      lifetimeCommission: (json['lifetime_commission'] as num?)?.toInt() ?? 0,
    );
  }
}
