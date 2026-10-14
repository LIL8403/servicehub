import 'package:flutter/foundation.dart';

/// A single working window on a given day, e.g. 08:00–12:00.
@immutable
class Shift {
  const Shift({required this.start, required this.end});

  /// `HH:mm` in 24-hour format, matching the backend storage.
  final String start;
  final String end;

  Shift copyWith({String? start, String? end}) =>
      Shift(start: start ?? this.start, end: end ?? this.end);

  Map<String, dynamic> toJson() => {'start': start, 'end': end};

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
    start: json['start']?.toString() ?? '08:00',
    end: json['end']?.toString() ?? '18:00',
  );

  /// Human label for a list row, e.g. "08:00 – 12:00".
  String get label => '$start – $end';
}

/// The artisan's weekly availability.
///
/// Mirrors the shape stored on `artisans.availability`. Keys are
/// lowercase weekday names in English (matching the backend).
@immutable
class Availability {
  const Availability({
    required this.acceptingRequests,
    required this.radiusKm,
    required this.days,
  });

  final bool acceptingRequests;
  final int radiusKm;

  /// Map from lowercase weekday name → list of shifts. An empty list
  /// means the artisan does not work that day.
  final Map<String, List<Shift>> days;

  static const weekdayKeys = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const weekdayLabels = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  Availability copyWith({
    bool? acceptingRequests,
    int? radiusKm,
    Map<String, List<Shift>>? days,
  }) {
    return Availability(
      acceptingRequests: acceptingRequests ?? this.acceptingRequests,
      radiusKm: radiusKm ?? this.radiusKm,
      days: days ?? this.days,
    );
  }

  /// Whether the artisan works on a given weekday.
  bool worksOn(String day) => (days[day] ?? const []).isNotEmpty;

  /// Number of working days in the week.
  int get workingDays => weekdayKeys.where((d) => worksOn(d)).length;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'accepting_requests': acceptingRequests,
      'radius_km': radiusKm,
    };
    for (final key in weekdayKeys) {
      json[key] = (days[key] ?? const <Shift>[])
          .map((s) => s.toJson())
          .toList(growable: false);
    }
    return json;
  }

  factory Availability.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Availability.empty();

    final days = <String, List<Shift>>{};
    for (final key in weekdayKeys) {
      final raw = json[key];
      if (raw is! List) {
        days[key] = const [];
        continue;
      }
      days[key] = raw
          .whereType<Map<String, dynamic>>()
          .map(Shift.fromJson)
          .toList(growable: false);
    }

    return Availability(
      acceptingRequests: json['accepting_requests'] == true,
      radiusKm: (json['radius_km'] as num?)?.toInt() ?? 25,
      days: days,
    );
  }

  /// Default availability for a new artisan: Mon–Fri 08:00–18:00.
  factory Availability.empty() {
    final days = <String, List<Shift>>{};
    for (final key in weekdayKeys) {
      days[key] = (key == 'saturday' || key == 'sunday')
          ? const []
          : const [Shift(start: '08:00', end: '18:00')];
    }
    return Availability(acceptingRequests: true, radiusKm: 25, days: days);
  }
}

/// The list of cities we offer as quick picks. Matches the cities
/// where ServiceHUB currently operates, ordered by population.
const kCameroonCities = [
  'Douala',
  'Yaoundé',
  'Bafoussam',
  'Bamenda',
  'Garoua',
  'Maroua',
  'Ngaoundéré',
  'Buea',
  'Limbe',
  'Kumba',
  'Kribi',
  'Ebolowa',
  'Dschang',
  'Bafang',
  'Foumban',
];
