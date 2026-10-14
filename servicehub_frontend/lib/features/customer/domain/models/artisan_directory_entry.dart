import 'package:flutter/foundation.dart';

/// A public artisan profile as returned by `GET /api/artisans`.
///
/// This is the customer-facing directory view — the endpoint used by
/// the Discover tab and the "Recommended for you" carousel. It does
/// not require a service request to be in flight, unlike the
/// request-scoped `ArtisanSummary`.
@immutable
class ArtisanDirectoryEntry {
  const ArtisanDirectoryEntry({
    required this.id,
    required this.userId,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.hasPhoto,
    required this.professionalTitle,
    required this.professionalDescription,
    required this.experienceYears,
    required this.serviceAreas,
    required this.latitude,
    required this.longitude,
    required this.ratingAverage,
    required this.reviewCount,
    required this.completedJobs,
    required this.responseRate,
    required this.languages,
    required this.verificationStatus,
  });

  final String id;
  final String userId;
  final String name;
  final String firstName;
  final String lastName;
  final bool hasPhoto;
  final String professionalTitle;
  final String professionalDescription;
  final int experienceYears;
  final List<String> serviceAreas;
  final double? latitude;
  final double? longitude;
  final double ratingAverage;
  final int reviewCount;
  final int completedJobs;
  final double responseRate;
  final List<String> languages;
  final String verificationStatus;

  bool get isVerified =>
      verificationStatus.toLowerCase() == 'verified';

  bool get respondsFast => responseRate >= 0.9;

  String get experienceLabel => '$experienceYears yrs exp';

  factory ArtisanDirectoryEntry.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? {};
    final areas = (json['service_areas'] as List?) ?? const [];
    final langs = (json['languages'] as List?) ?? const [];
    final location = json['location'] as Map<String, dynamic>?;

    double? lat;
    double? lng;
    final coords = (location?['coordinates'] as List?) ?? const [];
    if (coords.length == 2 && coords[0] is num && coords[1] is num) {
      // GeoJSON order: [lng, lat].
      lng = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
    }

    return ArtisanDirectoryEntry(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: user['id']?.toString() ?? '',
      name: user['name']?.toString() ?? '',
      firstName: user['first_name']?.toString() ?? '',
      lastName: user['last_name']?.toString() ?? '',
      hasPhoto: user['has_photo'] == true,
      professionalTitle: json['professional_title']?.toString() ?? '',
      professionalDescription:
          json['professional_description']?.toString() ?? '',
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      serviceAreas: areas
          .whereType<Map<String, dynamic>>()
          .map((a) => a['city']?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toList(),
      latitude: lat,
      longitude: lng,
      ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      completedJobs: (json['completed_jobs'] as num?)?.toInt() ?? 0,
      responseRate: (json['response_rate'] as num?)?.toDouble() ?? 0.0,
      languages: langs.map((l) => l.toString()).toList(),
      verificationStatus: json['verification_status']?.toString() ?? 'unverified',
    );
  }
}