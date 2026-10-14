import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';

class PaymentInitiation {
  const PaymentInitiation({
    required this.id,
    required this.status,
    required this.amount,
    this.redirectUrl,
    this.reference,
  });

  final String id;
  final String status;
  final double amount;
  final String? redirectUrl;
  final String? reference;

  factory PaymentInitiation.fromJson(Map<String, dynamic> json) {
    return PaymentInitiation(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'initiated',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      redirectUrl:
          json['redirect_url']?.toString() ?? json['payment_url']?.toString(),
      reference: json['reference']?.toString(),
    );
  }
}

class PaymentRepository {
  PaymentRepository({required this.apiService});

  final ApiService apiService;

  Future<PaymentInitiation> initiate({
    required String requestId,
    required String phone,
    required String idempotencyKey,
    required String provider,
  }) async {
    if (requestId.isEmpty) {
      throw const ApiException(
        message: 'A request ID is required to initiate a payment.',
        statusCode: 400,
      );
    }

    try {
      final response = await apiService.authenticatedPost(
        '/customer/service-requests/$requestId/payments',
        body: {
          'phone': phone,
          'idempotency_key': idempotencyKey,
          'provider': provider,
        },
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final payment = json['payment'] as Map<String, dynamic>?;

      if (payment == null) {
        throw const ApiException(
          message: 'The server returned an unexpected response format.',
          statusCode: 500,
        );
      }

      return PaymentInitiation.fromJson(payment);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to initiate payment: $e');
    }
  }

  Future<PaymentInitiation> reconcile(String paymentId) async {
    if (paymentId.isEmpty) {
      throw const ApiException(
        message: 'A payment ID is required to reconcile.',
        statusCode: 400,
      );
    }

    try {
      final response = await apiService.authenticatedPost(
        '/customer/payments/$paymentId/reconcile',
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final payment = json['payment'] as Map<String, dynamic>?;

      if (payment == null) {
        throw const ApiException(
          message: 'The server returned an unexpected response format.',
          statusCode: 500,
        );
      }

      return PaymentInitiation.fromJson(payment);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to reconcile payment: $e');
    }
  }
}