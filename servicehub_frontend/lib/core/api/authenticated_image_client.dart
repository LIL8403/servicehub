import 'package:http/http.dart' as http;

import 'token_storage.dart';

/// An http.Client that automatically adds the Bearer token to every
/// request. Used by CachedNetworkImage to fetch private profile photos.
class AuthenticatedImageClient extends http.BaseClient {
  AuthenticatedImageClient({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? const TokenStorage();

  final TokenStorage _tokenStorage;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _tokenStorage.getToken();

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}