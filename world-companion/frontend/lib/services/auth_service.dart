import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://127.0.0.1:8000";
  static const String _tokenKey = "auth_token";

  static Future<Map<String, dynamic>> register(
    String username,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/auth/register/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    _checkOk(res);

    final data = jsonDecode(res.body)["data"];
    await _saveToken(data["token"]);

    return data;
  }

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/auth/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    _checkOk(res);

    final data = jsonDecode(res.body)["data"];
    await _saveToken(data["token"]);

    return data;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  static Future<bool> verifyToken() async {
  final token = await getToken();

  if (token == null || token.isEmpty) {
    return false;
  }

  final res = await http.get(
    Uri.parse("$baseUrl/api/auth/profile/"),
    headers: {
      "Authorization": "Token $token",
    },
  );

  if (res.statusCode == 200) {
    return true;
  }

  if (res.statusCode == 401) {
    await logout();
    return false;
  }

  throw Exception("Unable to verify authentication");
}

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static void _checkOk(http.Response res) {
    if (res.statusCode >= 400) {
      String message = "Authentication failed";

      try {
        final body = jsonDecode(res.body);
        if (body["error"] != null) {
          message = body["error"].toString();
        }
      } catch (_) {
        // Keep the default message if response isn't valid JSON.
      }

      throw Exception(message);
    }
  }
}