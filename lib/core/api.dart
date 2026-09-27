import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

/// Any non-2xx response. [errors] holds Laravel's per-field messages (422).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException(this.statusCode, this.message, {this.errors});

  String get friendly {
    final e = errors;
    if (e != null && e.isNotEmpty) {
      final first = e.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return message;
  }

  @override
  String toString() => friendly;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException() : super(401, 'Your session has ended. Please log in again.');
}

/// Thin JSON client for the /api/customer/* endpoints.
class Api {
  Api._();
  static final Api instance = Api._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'bakeone_customer_token';
  static const _timeout = Duration(seconds: 20);

  String? _token;

  /// Called when the server rejects the saved token (e.g. it was revoked).
  void Function()? onUnauthorized;

  bool get hasToken => _token != null;

  Future<String?> loadToken() async {
    try {
      _token = await _storage.read(key: _tokenKey);
    } catch (_) {
      _token = null;
    }
    return _token;
  }

  Future<void> setToken(String? token) async {
    _token = token;
    try {
      if (token == null) {
        await _storage.delete(key: _tokenKey);
      } else {
        await _storage.write(key: _tokenKey, value: token);
      }
    } catch (_) {}
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && '$v'.isNotEmpty) q[k] = '$v';
    });
    return Uri.parse('$base/api/customer$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => http.get(_uri(path, query), headers: _headers));

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) =>
      _send(() => http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) =>
      _send(() => http.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request().timeout(_timeout);
    } on SocketException {
      throw ApiException(0, "Can't reach Bake One right now. Check your internet connection and try again.");
    } on TimeoutException {
      throw ApiException(0, 'The server took too long to respond. Please try again.');
    } on http.ClientException {
      throw ApiException(0, "Can't reach Bake One right now. Please try again.");
    }

    dynamic body;
    try {
      body = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
    } catch (_) {
      body = <String, dynamic>{};
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body is Map<String, dynamic>) return body;
      return {'data': body};
    }

    if (res.statusCode == 401) {
      onUnauthorized?.call();
      throw UnauthorizedException();
    }

    final map = body is Map<String, dynamic> ? body : <String, dynamic>{};
    final message = (map['message'] as String?)?.trim();
    throw ApiException(
      res.statusCode,
      (message == null || message.isEmpty) ? 'Something went wrong (${res.statusCode}). Please try again.' : message,
      errors: map['errors'] is Map<String, dynamic> ? map['errors'] as Map<String, dynamic> : null,
    );
  }
}
