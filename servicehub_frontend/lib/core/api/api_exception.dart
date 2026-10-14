class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic body;
  final Map<String, List<String>>? errors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.body,
    this.errors,
  });

  /// Extracts the first error message or returns the general message.
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

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException ($statusCode): $message';
    }
    return 'ApiException: $message';
  }
}
