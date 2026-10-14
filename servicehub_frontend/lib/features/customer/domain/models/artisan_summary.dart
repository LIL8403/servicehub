class ArtisanSummary {
  const ArtisanSummary({
    required this.id,
    required this.userId,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.hasPhoto,
    required this.professionalTitle,
    required this.professionalDescription,
    required this.bio,
    required this.experienceYears,
    required this.serviceAreas,
    required this.location,
    required this.availability,
    required this.ratingAverage,
    required this.reviewCount,
    required this.completedJobs,
    required this.responseRate,
    required this.cancellationRate,
    required this.languages,
    required this.certifications,
    required this.distanceKm,
  });

  final String id;
  final String userId;
  final String name;
  final String firstName;
  final String lastName;
  final bool hasPhoto;
  final String professionalTitle;
  final String professionalDescription;
  final String bio;
  final int experienceYears;
  final List<ServiceArea> serviceAreas;
  final Map<String, dynamic>? location;
  final Map<String, dynamic> availability;
  final double ratingAverage;
  final int reviewCount;
  final int completedJobs;
  final double responseRate;
  final double cancellationRate;
  final List<String> languages;
  final List<dynamic> certifications;
  final double? distanceKm;

  bool get respondsFast => responseRate >= 0.9;

  String get experienceLabel => '$experienceYears yrs exp';

  String get jobsLabel => '$completedJobs jobs';

  String? get distanceLabel =>
      distanceKm != null ? '${distanceKm!.toStringAsFixed(1)} km' : null;

  factory ArtisanSummary.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? {};
    final areas = (json['service_areas'] as List?) ?? [];
    final langs = (json['languages'] as List?) ?? [];
    final certs = (json['certifications'] as List?) ?? [];

    return ArtisanSummary(
      id: json['id']?.toString() ?? '',
      userId: user['id']?.toString() ?? '',
      name: user['name']?.toString() ?? '',
      firstName: user['first_name']?.toString() ?? '',
      lastName: user['last_name']?.toString() ?? '',
      hasPhoto: user['has_photo'] == true,
      professionalTitle: json['professional_title']?.toString() ?? '',
      professionalDescription:
          json['professional_description']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      serviceAreas: areas
          .whereType<Map<String, dynamic>>()
          .map((a) => ServiceArea.fromJson(a))
          .toList(),
      location: json['location'] as Map<String, dynamic>?,
      availability: (json['availability'] as Map<String, dynamic>?) ?? {},
      ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      completedJobs: (json['completed_jobs'] as num?)?.toInt() ?? 0,
      responseRate: (json['response_rate'] as num?)?.toDouble() ?? 0.0,
      cancellationRate:
          (json['cancellation_rate'] as num?)?.toDouble() ?? 0.0,
      languages: langs.map((l) => l.toString()).toList(),
      certifications: certs,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}

class ServiceArea {
  const ServiceArea({required this.city, required this.radiusKm});

  final String city;
  final int radiusKm;

  factory ServiceArea.fromJson(Map<String, dynamic> json) {
    return ServiceArea(
      city: json['city']?.toString() ?? '',
      radiusKm: (json['radius_km'] as num?)?.toInt() ?? 0,
    );
  }
}