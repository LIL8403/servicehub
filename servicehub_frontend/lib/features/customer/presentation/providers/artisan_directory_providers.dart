import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/artisan_directory_repository.dart';
import '../../domain/models/artisan_directory_entry.dart';

final artisanDirectoryRepositoryProvider = Provider<ArtisanDirectoryRepository>(
  (ref) {
    final api = ref.watch(apiServiceProvider);
    return ArtisanDirectoryRepository(apiService: api);
  },
);

/// Parameters for a directory query. Using a record type so we can
/// family the provider by a value that has structural equality.
typedef ArtisanDirectoryQuery = ({
  String? serviceId,
  String? search,
  double? latitude,
  double? longitude,
  int? limit,
});

/// Searches artisans. Auto-disposes so returning to the Discover tab
/// refetches fresh data.
final artisanDirectoryProvider = FutureProvider.autoDispose
    .family<List<ArtisanDirectoryEntry>, ArtisanDirectoryQuery>((
      ref,
      query,
    ) async {
      final repo = ref.watch(artisanDirectoryRepositoryProvider);
      return repo.search(
        serviceId: query.serviceId,
        search: query.search,
        latitude: query.latitude,
        longitude: query.longitude,
        limit: query.limit,
      );
    });

/// Convenience provider for the Discover tab. Uses no filters and
/// returns a broad list of verified artisans.
final featuredArtisansProvider =
    FutureProvider.autoDispose<List<ArtisanDirectoryEntry>>((ref) {
      final repo = ref.watch(artisanDirectoryRepositoryProvider);
      return repo.search(limit: 20);
    });

/// Fetches a single artisan by ID from the public directory. Used by
/// the read-only profile page when no service request is in flight.
///
/// Auto-disposes when the profile page unmounts.
final publicArtisanProvider = FutureProvider.autoDispose
    .family<ArtisanDirectoryEntry?, String>((ref, artisanId) async {
      if (artisanId.isEmpty) return null;
      final repo = ref.watch(artisanDirectoryRepositoryProvider);
      return repo.fetchById(artisanId);
    });
