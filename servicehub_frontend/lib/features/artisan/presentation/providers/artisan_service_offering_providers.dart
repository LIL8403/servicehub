import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/artisan_service_offering_repository.dart';
import '../../domain/models/service_offering.dart';

final artisanServiceOfferingRepositoryProvider =
    Provider<ArtisanServiceOfferingRepository>((ref) {
      final api = ref.watch(apiServiceProvider);
      return ArtisanServiceOfferingRepository(apiService: api);
    });

final artisanServiceOfferingsProvider =
    FutureProvider.autoDispose<List<ServiceOffering>>((ref) {
      return ref.watch(artisanServiceOfferingRepositoryProvider).list();
    });

/// Tracks in-flight mutations from the offerings screen.
class OfferingActionState {
  const OfferingActionState({this.isSubmitting = false, this.errorMessage});

  final bool isSubmitting;
  final String? errorMessage;

  OfferingActionState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearErrors = false,
  }) {
    return OfferingActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OfferingActionNotifier extends StateNotifier<OfferingActionState> {
  OfferingActionNotifier(this._ref) : super(const OfferingActionState());

  final Ref _ref;

  Future<bool> add({
    required String serviceId,
    double? startingPrice,
    String? description,
  }) => _run(
    'add',
    () => _ref
        .read(artisanServiceOfferingRepositoryProvider)
        .create(
          serviceId: serviceId,
          startingPrice: startingPrice,
          description: description,
        ),
  );

  Future<bool> update(
    String offeringId, {
    double? startingPrice,
    String? description,
    bool? isActive,
    bool clearStartingPrice = false,
    bool clearDescription = false,
  }) => _run(
    'update',
    () => _ref
        .read(artisanServiceOfferingRepositoryProvider)
        .update(
          offeringId,
          startingPrice: startingPrice,
          description: description,
          isActive: isActive,
          clearStartingPrice: clearStartingPrice,
          clearDescription: clearDescription,
        ),
  );

  Future<bool> remove(String offeringId) => _run(
    'remove',
    () =>
        _ref.read(artisanServiceOfferingRepositoryProvider).destroy(offeringId),
  );

  Future<bool> _run(String label, Future<Object?> Function() action) async {
    state = state.copyWith(isSubmitting: true, clearErrors: true);
    try {
      await action();
      if (!mounted) return true;
      state = state.copyWith(isSubmitting: false);
      _ref.invalidate(artisanServiceOfferingsProvider);
      return true;
    } on Exception catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceFirst('ApiException: ', ''),
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Something went wrong.',
      );
      return false;
    }
  }

  void reset() => state = const OfferingActionState();
}

final offeringActionProvider =
    StateNotifierProvider.autoDispose<
      OfferingActionNotifier,
      OfferingActionState
    >((ref) => OfferingActionNotifier(ref));
