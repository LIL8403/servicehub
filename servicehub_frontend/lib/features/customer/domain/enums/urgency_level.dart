enum UrgencyLevel {
  low,
  medium,
  high;

  String get apiValue {
    switch (this) {
      case UrgencyLevel.low:
        return 'low';
      case UrgencyLevel.medium:
        return 'medium';
      case UrgencyLevel.high:
        return 'high';
    }
  }
}