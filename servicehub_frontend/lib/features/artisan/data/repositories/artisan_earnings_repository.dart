import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../domain/models/earnings_summary.dart';
import '../../domain/models/payout_record.dart';

class ArtisanEarningsRepository {
  ArtisanEarningsRepository({required this.apiService});

  final ApiService apiService;

  Future<EarningsSummary> fetchSummary() async {
    try {
      final response = await apiService.authenticatedGet(
        '/artisan/earnings/summary',
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final summary = json['summary'] as Map<String, dynamic>?;
      if (summary == null) {
        throw const ApiException(
          message: 'Unexpected response shape.',
          statusCode: 500,
        );
      }
      return EarningsSummary.fromJson(summary);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load earnings: $e');
    }
  }

  Future<PayoutPage> fetchPayouts({int page = 1, int perPage = 20}) async {
    try {
      final response = await apiService.authenticatedGet(
        '/artisan/payouts?page=$page&per_page=$perPage',
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PayoutPage.fromJson(json);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load payouts: $e');
    }
  }
}
