// api_service.dart
// Talks to the Django backend built in /backend.
// Change baseUrl to your machine's IP when testing on a physical device
// (localhost won't resolve to your dev machine from a phone).

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android emulator -> host machine.
  // Use your machine's LAN IP for a physical device.
  static const String baseUrl = "http://192.168.1.4:8000";

  static Future<Map<String, dynamic>> classifyIntent(String text) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/intent/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text}),
    );
    _checkOk(res);
    return jsonDecode(res.body)["data"];
  }

  static Future<Map<String, dynamic>> optimizeRoute(
      String startId, List<String> stopIds) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/route/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"start_id": startId, "stop_ids": stopIds}),
    );
    _checkOk(res);
    return jsonDecode(res.body)["data"];
  }

  static Future<Map<String, dynamic>> getPois() async {
    final res = await http.get(Uri.parse("$baseUrl/api/pois/"));
    _checkOk(res);
    return jsonDecode(res.body)["data"];
  }

  static void _checkOk(http.Response res) {
    if (res.statusCode >= 400) {
      throw Exception("API error ${res.statusCode}: ${res.body}");
    }
  }
}
