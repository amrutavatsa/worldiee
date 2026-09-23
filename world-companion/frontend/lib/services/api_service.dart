import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  // ---------------------------------------------------------------------------
  // Common headers
  // ---------------------------------------------------------------------------

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Token $token",
    };
  }

  static void _checkOk(http.Response res) {
    if (res.statusCode >= 400) {
      throw Exception(
        "API error ${res.statusCode}: ${res.body}",
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Authentication / Profile
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/auth/profile/"),
      headers: await _headers(),
    );

    _checkOk(res);

    final body = jsonDecode(res.body);

    return Map<String, dynamic>.from(body["data"]);
  }

  // ---------------------------------------------------------------------------
  // Intent
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> classifyIntent(
    String text,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/intent/"),
      headers: await _headers(),
      body: jsonEncode({
        "text": text,
      }),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  // ---------------------------------------------------------------------------
  // Route
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> optimizeRoute(
    String startId,
    List<String> stopIds,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/route/"),
      headers: await _headers(),
      body: jsonEncode({
        "start_id": startId,
        "stop_ids": stopIds,
      }),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  // ---------------------------------------------------------------------------
  // POIs
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getPois() async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/pois/"),
      headers: await _headers(),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  // ---------------------------------------------------------------------------
  // Place information
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getPlaceInfo(
    String placeId,
  ) async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/places/$placeId/info/"),
      headers: await _headers(),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  // ---------------------------------------------------------------------------
  // Reviews
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getReviews({
    required String targetType,
    required String targetId,
  }) async {
    final res = await http.get(
      Uri.parse(
        "$baseUrl/api/reviews/$targetType/$targetId/",
      ),
      headers: await _headers(),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  static Future<Map<String, dynamic>> createReview({
    required String targetType,
    required String targetId,
    required int rating,
    required String comment,
    String? authorName,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/reviews/"),
      headers: await _headers(),
      body: jsonEncode({
        "target_type": targetType,
        "target_id": targetId,
        "rating": rating,
        "comment": comment,
        if (authorName != null && authorName.isNotEmpty)
          "author_name": authorName,
      }),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  // ---------------------------------------------------------------------------
  // Nearby places
  // ---------------------------------------------------------------------------

  static Future<List<dynamic>> getNearbyPlaces({
    String? category,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/api/places/nearby/",
    ).replace(
      queryParameters: {
        if (category != null && category.isNotEmpty)
          "category": category,
      },
    );

    final res = await http.get(
      uri,
      headers: await _headers(),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  // ---------------------------------------------------------------------------
  // Hotels
  // ---------------------------------------------------------------------------

  static Future<List<dynamic>> getHotels({
    String? area,
    double? maxPrice,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/api/hotels/",
    ).replace(
      queryParameters: {
        if (area != null && area.isNotEmpty)
          "area": area,
        if (maxPrice != null)
          "max_price": maxPrice.toString(),
      },
    );

    final res = await http.get(
      uri,
      headers: await _headers(),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  // ---------------------------------------------------------------------------
  // Bookings
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> createBooking({
    required String hotelId,
    required String guestName,
    required String roomType,
    required String checkIn,
    required String checkOut,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/bookings/"),
      headers: await _headers(),
      body: jsonEncode({
        "hotel_id": hotelId,
        "guest_name": guestName,
        "room_type": roomType,
        "check_in": checkIn,
        "check_out": checkOut,
      }),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  static Future<List<dynamic>> getBookingHistory() async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/bookings/history/"),
      headers: await _headers(),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  // ---------------------------------------------------------------------------
  // Emergency contacts
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> createEmergencyContact({
    required String name,
    required String phone,
    String relationship = "",
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/emergency-contacts/"),
      headers: await _headers(),
      body: jsonEncode({
        "name": name,
        "phone": phone,
        "relationship": relationship,
      }),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  static Future<List<dynamic>> getEmergencyContacts() async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/emergency-contacts/list/"),
      headers: await _headers(),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  // ---------------------------------------------------------------------------
  // SOS
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> triggerSos({
    double? latitude,
    double? longitude,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/sos/trigger/"),
      headers: await _headers(),
      body: jsonEncode({
        if (latitude != null) "latitude": latitude,
        if (longitude != null) "longitude": longitude,
      }),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  static Future<Map<String, dynamic>> activateSos(
    String eventId,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/sos/$eventId/activate/"),
      headers: await _headers(),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  static Future<Map<String, dynamic>> resolveSos(
    String eventId,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/sos/$eventId/resolve/"),
      headers: await _headers(),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  // ---------------------------------------------------------------------------
  // Itinerary
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> createItinerary({
    required String title,
    required List<Map<String, dynamic>> stops,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/itinerary/create/"),
      headers: await _headers(),
      body: jsonEncode({
        "title": title,
        "stops": stops,
      }),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  static Future<List<Map<String, dynamic>>> getItineraries() async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/itinerary/"),
      headers: await _headers(),
    );

    _checkOk(res);

    final body = jsonDecode(res.body);

    return List<Map<String, dynamic>>.from(
      (body["data"] as List).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );
  }

  static Future<Map<String, dynamic>> getItinerary(
    String itineraryId,
  ) async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/itinerary/$itineraryId/"),
      headers: await _headers(),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  // ---------------------------------------------------------------------------
  // Preferences
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> savePreferences({
    required List<String> interests,
    required String budget,
    required String travelStyle,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/preferences/"),
      headers: await _headers(),
      body: jsonEncode({
        "interests": interests,
        "budget": budget,
        "travel_style": travelStyle,
      }),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  // ---------------------------------------------------------------------------
  // Recommendations
  // ---------------------------------------------------------------------------

  static Future<List<dynamic>> getRecommendations() async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/recommendations/"),
      headers: await _headers(),
    );

    _checkOk(res);

    return jsonDecode(res.body)["data"];
  }

  // ---------------------------------------------------------------------------
  // WorldCompanion AI Assistant
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> sendAssistantMessage(
    String message,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/assistant/"),
      headers: await _headers(),
      body: jsonEncode({
        "message": message,
      }),
    );

    _checkOk(res);

    final body = jsonDecode(res.body);

    return Map<String, dynamic>.from(body);
  }
}