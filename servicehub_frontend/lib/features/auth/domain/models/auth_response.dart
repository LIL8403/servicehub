import 'user.dart';

class AuthResponse {
  final String token;
  final User user;

  const AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Check if the response is nested in 'data'
    final map = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final token = (map['token'] ?? json['token']) as String? ?? '';
    final userRaw = map['user'] ?? json['user'];

    final Map<String, dynamic> userMap;
    if (userRaw is Map<String, dynamic>) {
      userMap = userRaw;
    } else {
      userMap = const {};
    }

    return AuthResponse(
      token: token,
      user: User.fromJson(userMap),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}
