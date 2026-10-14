import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return PaymentRepository(apiService: api);
});

class PaymentActionState {
  const PaymentActionState({
    this.isSubmitting = false,
    this.errorMessage,
    this.initiation,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final PaymentInitiation? initiation;

  PaymentActionState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    PaymentInitiation? initiation,
    bool clearErrors = false,
  }) {
    return PaymentActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      initiation: initiation ?? this.initiation,
    );
  }
}

class PaymentActionNotifier extends StateNotifier<PaymentActionState> {
  PaymentActionNotifier(this._ref) : super(const PaymentActionState());

  final Ref _ref;

  /// Generates a UUID v4 for idempotency. Laravel's `uuid` validation
  /// rule requires the standard 8-4-4-4-12 hex format with dashes.
  String generateIdempotencyKey() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));

    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();

    return '${h.substring(0, 8)}-'
        '${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-'
        '${h.substring(20, 32)}';
  }

  Future<PaymentInitiation?> initiate({
    required String requestId,
    required String phone,
    required String idempotencyKey,
    required String provider,
  }) async {
    state = state.copyWith(isSubmitting: true, clearErrors: true);

    try {
      final result = await _ref.read(paymentRepositoryProvider).initiate(
            requestId: requestId,
            phone: phone,
            idempotencyKey: idempotencyKey,
            provider: provider,
          );
      if (!mounted) return result;
      state = state.copyWith(isSubmitting: false, initiation: result);
      return result;
    } on ApiException catch (e) {
      if (!mounted) return null;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.firstErrorMessage,
      );
      return null;
    } catch (_) {
      if (!mounted) return null;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'An unexpected error occurred.',
      );
      return null;
    }
  }

  void reset() {
    state = const PaymentActionState();
  }
}

final paymentActionProvider = StateNotifierProvider.autoDispose<
    PaymentActionNotifier, PaymentActionState>(
  (ref) => PaymentActionNotifier(ref),
);