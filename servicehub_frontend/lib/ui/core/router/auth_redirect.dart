class AuthRedirect {
  const AuthRedirect._();

  static const Set<String> _guestRoutes = {
    '/landing',
    '/login',
    '/register',
    '/service-categories',
  };

  static String? redirect({
    required bool isAuthenticated,
    bool isLoading = false,
    required String location,
    String? fullLocation,
    String? redirectParam,
    String homeRoute = '/customer-home',
  }) {
    if (isLoading && location == '/') {
      return null;
    }

    final isGuestRoute = _guestRoutes.contains(location);

    if (!isAuthenticated) {
      if (location == '/') {
        return '/landing';
      }
      if (isGuestRoute) {
        return null;
      }
      final intended = fullLocation ?? location;
      final encoded = Uri.encodeComponent(intended);
      return '/login?redirect=$encoded';
    }

    if (location == '/login' || location == '/register') {
      if (redirectParam != null && redirectParam.isNotEmpty) {
        return redirectParam;
      }
      return homeRoute;
    }

    if (location == '/' || location == '/landing') {
      return homeRoute;
    }

    return null;
  }
}