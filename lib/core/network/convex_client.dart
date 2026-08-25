import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Convex Client for Flutter
/// Handles Queries, Mutations, and Actions with token/auth header support
class ConvexClient {
  final String deploymentUrl;
  String? _authToken;

  ConvexClient({required this.deploymentUrl});

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Convex-Client': 'flutter-duka-1.0.0',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Run a Convex Mutation (e.g. `products:createProduct`, `sales:createSale`)
  Future<dynamic> mutation(String functionPath, Map<String, dynamic> args) async {
    final url = Uri.parse('$deploymentUrl/api/mutation');
    final body = jsonEncode({
      'path': functionPath,
      'args': args,
      'format': 'json',
    });

    try {
      final response = await http.post(url, headers: _headers, body: body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['value'];
        } else {
          throw Exception(data['errorMessage'] ?? 'Convex mutation failed: ${response.body}');
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Convex Mutation error on [$functionPath]: $e');
      }
      rethrow;
    }
  }

  /// Run a Convex Query (e.g. `products:listProducts`, `sales:listSales`)
  Future<dynamic> query(String functionPath, Map<String, dynamic> args) async {
    final url = Uri.parse('$deploymentUrl/api/query');
    final body = jsonEncode({
      'path': functionPath,
      'args': args,
      'format': 'json',
    });

    try {
      final response = await http.post(url, headers: _headers, body: body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['value'];
        } else {
          throw Exception(data['errorMessage'] ?? 'Convex query failed: ${response.body}');
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Convex Query error on [$functionPath]: $e');
      }
      rethrow;
    }
  }

  /// Run a Convex Action (e.g. `payments:initiateMtnMomoCollection`)
  Future<dynamic> action(String functionPath, Map<String, dynamic> args) async {
    final url = Uri.parse('$deploymentUrl/api/action');
    final body = jsonEncode({
      'path': functionPath,
      'args': args,
      'format': 'json',
    });

    try {
      final response = await http.post(url, headers: _headers, body: body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['value'];
        } else {
          throw Exception(data['errorMessage'] ?? 'Convex action failed: ${response.body}');
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Convex Action error on [$functionPath]: $e');
      }
      rethrow;
    }
  }
}
