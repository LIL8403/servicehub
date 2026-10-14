class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final List<String> roles;
  final String activeRole;
  final DateTime? emailVerifiedAt;
  final String accountStatus;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.roles,
    required this.activeRole,
    this.emailVerifiedAt,
    required this.accountStatus,
  });

  String get fullName {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName.isNotEmpty ? firstName : lastName;
  }

  bool get isEmailVerified => emailVerifiedAt != null;

  bool get isActive => accountStatus == 'active';

  bool hasRole(String role) => roles.contains(role);

  factory User.fromJson(Map<String, dynamic> json) {
    // Determine ID from 'id' or MongoDB '_id'
    final rawId = json['id'] ?? json['_id'];
    final id = rawId?.toString() ?? '';

    // Handle names (support both first_name/last_name and single 'name' field)
    String firstName = json['first_name'] as String? ?? json['firstName'] as String? ?? '';
    String lastName = json['last_name'] as String? ?? json['lastName'] as String? ?? '';

    if (firstName.isEmpty && lastName.isEmpty && json['name'] is String) {
      final nameParts = (json['name'] as String).trim().split(RegExp(r'\s+'));
      if (nameParts.isNotEmpty) {
        firstName = nameParts.first;
        if (nameParts.length > 1) {
          lastName = nameParts.sublist(1).join(' ');
        }
      }
    }

    final email = json['email'] as String? ?? '';
    final phone = json['phone'] as String? ?? '';

    // Roles list
    final rawRoles = json['roles'];
    final List<String> roles;
    if (rawRoles is List) {
      roles = rawRoles.map((e) => e.toString()).toList();
    } else {
      roles = const [];
    }

    final activeRole = json['active_role'] as String? ??
        json['activeRole'] as String? ??
        (roles.isNotEmpty ? roles.first : 'customer');

    // Email verified at
    DateTime? emailVerifiedAt;
    final rawVerifiedAt = json['email_verified_at'] ?? json['emailVerifiedAt'];
    if (rawVerifiedAt != null) {
      emailVerifiedAt = DateTime.tryParse(rawVerifiedAt.toString());
    }

    // Account status
    final accountStatus = json['account_status'] as String? ??
        json['accountStatus'] as String? ??
        json['status'] as String? ??
        'active';

    return User(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      roles: roles,
      activeRole: activeRole,
      emailVerifiedAt: emailVerifiedAt,
      accountStatus: accountStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'name': fullName,
      'email': email,
      'phone': phone,
      'roles': roles,
      'active_role': activeRole,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'account_status': accountStatus,
    };
  }

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    List<String>? roles,
    String? activeRole,
    DateTime? emailVerifiedAt,
    String? accountStatus,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roles: roles ?? this.roles,
      activeRole: activeRole ?? this.activeRole,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          activeRole == other.activeRole &&
          accountStatus == other.accountStatus;

  @override
  int get hashCode =>
      id.hashCode ^ email.hashCode ^ activeRole.hashCode ^ accountStatus.hashCode;
}
