import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';
import '../../domain/models/payment_record.dart';

class CustomerPaymentsRepository {
  CustomerPaymentsRepository({required this.apiService});

  final ApiService apiService;

  Future<List<PaymentRecord>> list({int limit = 50}) async {
    try {
      final response = await apiService.authenticatedGet(
        '/customer/payments?limit=$limit',
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['payments'] as List?) ?? const [];

      return list
          .whereType<Map<String, dynamic>>()
          .map(PaymentRecord.fromJson)
          .where((p) => p.id.isNotEmpty)
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load payments: $e');
    }
  }
}