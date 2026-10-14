import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:image_picker/image_picker.dart';

import '../constants/api_constants.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class ApiService {
  final TokenStorage _tokenStorage;
  final http.Client _client;
  final String _baseUrl;

  ApiService({TokenStorage? tokenStorage, http.Client? client, String? baseUrl})
    : _tokenStorage = tokenStorage ?? const TokenStorage(),
      _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConstants.baseUrl;

  static const Duration _timeoutDuration = Duration(seconds: 10);

  Future<Map<String, String>> _buildHeaders({
    bool authenticated = false,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?additionalHeaders,
    };

    if (authenticated) {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw const ApiException(
          message: 'Authentication token not found.',
          statusCode: 401,
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Uri _buildUri(String endpoint) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$_baseUrl$cleanEndpoint');
  }

  Future<http.Response> _sendRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(_timeoutDuration);
      return _processResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message:
            'Request timed out. Please check your connection and try again.',
        statusCode: 408,
      );
    } on http.ClientException catch (e) {
      throw ApiException(message: 'Network error: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Unexpected network error: $e');
    }
  }

  http.Response _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    String message = 'Request failed with status ${response.statusCode}';
    Map<String, List<String>>? validationErrors;
    dynamic bodyData;

    try {
      if (response.body.isNotEmpty) {
        bodyData = jsonDecode(response.body);
        if (bodyData is Map<String, dynamic>) {
          if (bodyData['message'] is String &&
              (bodyData['message'] as String).isNotEmpty) {
            message = bodyData['message'] as String;
          } else if (bodyData['error'] is Map &&
              bodyData['error']['message'] is String) {
            message = bodyData['error']['message'] as String;
          } else if (bodyData['error'] is String) {
            message = bodyData['error'] as String;
          }

          // Parse Laravel validation error schema (422)
          final rawErrors =
              bodyData['errors'] ??
              (bodyData['error'] is Map ? bodyData['error']['details'] : null);
          if (rawErrors is Map<String, dynamic>) {
            validationErrors = {};
            for (final entry in rawErrors.entries) {
              if (entry.value is List) {
                validationErrors[entry.key] = (entry.value as List)
                    .map((e) => e.toString())
                    .toList();
              } else if (entry.value is String) {
                validationErrors[entry.key] = [entry.value as String];
              }
            }
          }
        }
      }
    } catch (_) {
      // Body is not JSON (e.g., HTML 500 error)
    }

    throw ApiException(
      message: message,
      statusCode: response.statusCode,
      body: bodyData ?? response.body,
      errors: validationErrors,
    );
  }

  Future<http.Response> get(
    String endpoint, {
    bool authenticated = false,
    Map<String, String>? headers,
  }) async {
    final finalHeaders = await _buildHeaders(
      authenticated: authenticated,
      additionalHeaders: headers,
    );
    return _sendRequest(
      () => _client.get(_buildUri(endpoint), headers: finalHeaders),
    );
  }

  Future<http.Response> post(
    String endpoint, {
    dynamic body,
    bool authenticated = false,
    Map<String, String>? headers,
  }) async {
    final finalHeaders = await _buildHeaders(
      authenticated: authenticated,
      additionalHeaders: headers,
    );
    final encodedBody = body is String
        ? body
        : (body != null ? jsonEncode(body) : null);
    return _sendRequest(
      () => _client.post(
        _buildUri(endpoint),
        headers: finalHeaders,
        body: encodedBody,
      ),
    );
  }

  Future<http.Response> put(
    String endpoint, {
    dynamic body,
    bool authenticated = false,
    Map<String, String>? headers,
  }) async {
    final finalHeaders = await _buildHeaders(
      authenticated: authenticated,
      additionalHeaders: headers,
    );
    final encodedBody = body is String
        ? body
        : (body != null ? jsonEncode(body) : null);
    return _sendRequest(
      () => _client.put(
        _buildUri(endpoint),
        headers: finalHeaders,
        body: encodedBody,
      ),
    );
  }

  Future<http.Response> patch(
    String endpoint, {
    dynamic body,
    bool authenticated = false,
    Map<String, String>? headers,
  }) async {
    final finalHeaders = await _buildHeaders(
      authenticated: authenticated,
      additionalHeaders: headers,
    );
    final encodedBody = body is String
        ? body
        : (body != null ? jsonEncode(body) : null);
    return _sendRequest(
      () => _client.patch(
        _buildUri(endpoint),
        headers: finalHeaders,
        body: encodedBody,
      ),
    );
  }

  Future<http.Response> delete(
    String endpoint, {
    dynamic body,
    bool authenticated = false,
    Map<String, String>? headers,
  }) async {
    final finalHeaders = await _buildHeaders(
      authenticated: authenticated,
      additionalHeaders: headers,
    );
    final encodedBody = body is String
        ? body
        : (body != null ? jsonEncode(body) : null);
    return _sendRequest(
      () => _client.delete(
        _buildUri(endpoint),
        headers: finalHeaders,
        body: encodedBody,
      ),
    );
  }

  // Convenience aliases for authenticated calls
  Future<http.Response> authenticatedGet(
    String endpoint, {
    Map<String, String>? headers,
  }) => get(endpoint, authenticated: true, headers: headers);

  Future<http.Response> authenticatedPost(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) => post(endpoint, body: body, authenticated: true, headers: headers);

  /// Sends a `multipart/form-data` POST. Used when the request
  /// carries binary files (photo uploads).
  ///
  /// [fields] are simple key/value pairs. The backend expects
  /// arrays to be encoded with `field[]` keys — pass them
  /// pre-formatted (e.g. `{'images[]': 'image-0'}` isn't needed;
  /// use [files] for that).
  ///
  /// [files] is a list of (fieldName, filename, bytes, mimeType)
  /// records. The field name defaults to the backend's expectation
  /// for that endpoint — pass `'images[]'` for photo arrays.
  Future<http.Response> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    List<http.MultipartFile> files = const [],
    bool authenticated = false,
    Map<String, String>? headers,
  }) async {
    final finalHeaders = await _buildHeaders(
      authenticated: authenticated,
      additionalHeaders: headers,
    );
    // Content-Type is set by the multipart encoder — strip it from
    // our default headers, otherwise http refuses to override it.
    finalHeaders.remove('Content-Type');

    final request = http.MultipartRequest('POST', _buildUri(endpoint))
      ..headers.addAll(finalHeaders)
      ..fields.addAll(fields)
      ..files.addAll(files);

    try {
      final streamed = await _client
          .send(request)
          .timeout(
            const Duration(seconds: 60), // uploads are slower than GETs
          );
      final response = await http.Response.fromStream(streamed);
      return _processResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message:
            'Upload timed out. Please check your connection and try again.',
        statusCode: 408,
      );
    } on http.ClientException catch (e) {
      throw ApiException(message: 'Network error: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Unexpected upload error: $e');
    }
  }

  /// Convenience helper that turns an `XFile` (from image_picker)
  /// into an `http.MultipartFile` with the correct MIME type inferred
  /// from the extension.
  Future<http.MultipartFile> multipartFileFromXFile(
    String fieldName,
    XFile file,
  ) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
    return http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: file.name,
      contentType: MediaType.parse(mime),
    );
  }

  Future<http.Response> authenticatedPut(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) => put(endpoint, body: body, authenticated: true, headers: headers);

  Future<http.Response> authenticatedPatch(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) => patch(endpoint, body: body, authenticated: true, headers: headers);

  Future<http.Response> authenticatedDelete(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) => delete(endpoint, body: body, authenticated: true, headers: headers);
}
