import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';

/// The current commission settings from the backend.
class CommissionSettings {
  const CommissionSettings({
    required this.rate,
    required this.minimum,
    required this.maximum,
  });

  /// Decimal rate (e.g. 0.07 for 7%).
  final double rate;
  final double minimum;
  final double maximum;

  double get ratePercent => rate * 100;
  double get minPercent => minimum * 100;
  double get maxPercent => maximum * 100;

  factory CommissionSettings.fromJson(Map<String, dynamic> json) {
    return CommissionSettings(
      rate: (json['commission_rate'] as num?)?.toDouble() ?? 0.0,
      minimum: (json['minimum'] as num?)?.toDouble() ?? 0.0,
      maximum: (json['maximum'] as num?)?.toDouble() ?? 0.30,
    );
  }
}

class AdminPlatformSettingsRepository {
  AdminPlatformSettingsRepository({required this.apiService});

  final ApiService apiService;

  Future<CommissionSettings> fetchCommission() async {
    try {
      final response =
          await apiService.authenticatedGet('/admin/settings/commission');
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return CommissionSettings.fromJson(json);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load commission: $e');
    }
  }

  Future<void> updateCommission({
    required double rate,
    required String reason,
  }) async {
    try {
      await apiService.authenticatedPut(
        '/admin/settings/commission',
        body: {
          'rate': rate,
          'reason': reason,
        },
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to update commission: $e');
    }
  }
}