class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? errors;

  const AuthException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  /// Returns the first validation error if present, or [message].
  String get firstErrorMessage {
    if (errors != null && errors!.isNotEmpty) {
      final firstKey = errors!.keys.first;
      final firstList = errors![firstKey];
      if (firstList != null && firstList.isNotEmpty) {
        return firstList.first;
      }
    }
    return message;
  }

  /// Returns the first error message for a specific field, if any.
  String? fieldError(String fieldName) {
    if (errors != null && errors!.containsKey(fieldName)) {
      final list = errors![fieldName];
      if (list != null && list.isNotEmpty) {
        return list.first;
      }
    }
    return null;
  }

  @override
  String toString() {
    if (statusCode != null) {
      return 'AuthException ($statusCode): $message';
    }
    return 'AuthException: $message';
  }
}
