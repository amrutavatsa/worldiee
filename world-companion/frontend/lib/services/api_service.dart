
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  // ---------------------------------------------------------------------------
  // Common headers and response handling
  // ---------------------------------------------------------------------------

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Token $token',
    };
  }

  static void _checkOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'API error ${response.statusCode}: ${response.body}',
      );
    }
  }

  static dynamic _decodeJson(http.Response response) {
    try {
      return jsonDecode(response.body);
    } on FormatException catch (error) {
      throw FormatException(
        'Invalid JSON returned by ${response.request?.url ?? 'the API'}: '
        '${error.message}',
      );
    }
  }

  static Map<String, dynamic> _asMap(
    dynamic value, {
    required String context,
  }) {
    if (value is! Map) {
      throw FormatException(
        '$context must return a JSON object.',
      );
    }

    return Map<String, dynamic>.from(value);
  }

  static Map<String, dynamic> _dataMap(
    dynamic body, {
    required String context,
  }) {
    final response = _asMap(body, context: context);
    final data = response['data'] ?? response;

    return _asMap(data, context: '$context data');
  }

  static List<dynamic> _asList(
    dynamic value, {
    required String context,
  }) {
    if (value is! List) {
      throw FormatException(
        '$context must return a JSON list.',
      );
    }

    return List<dynamic>.from(value);
  }

  static void _validateCoordinates({
    required double latitude,
    required double longitude,
  }) {
    if (!latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180) {
      throw ArgumentError(
        'Invalid coordinates: latitude must be between -90 and 90 '
        'and longitude must be between -180 and 180.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Authentication / Profile
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/profile/'),
      headers: await _headers(),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'Profile API');
  }

  static Future<Map<String, dynamic>> googleLogin(
    String idToken,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/google/'),
      headers: await _headers(),
      body: jsonEncode({
        'id_token': idToken,
      }),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'Google login API');
  }

  // ---------------------------------------------------------------------------
  // Intent
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> classifyIntent(
    String text,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/intent/'),
      headers: await _headers(),
      body: jsonEncode({
        'text': text,
      }),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'Intent API');
  }

  // ---------------------------------------------------------------------------
  // Route — Existing A* routing
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> optimizeRoute(
    String startId,
    List<String> stopIds,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/route/'),
      headers: await _headers(),
      body: jsonEncode({
        'start_id': startId,
        'stop_ids': stopIds,
      }),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'A* route API');
  }

  // ---------------------------------------------------------------------------
  // Route — Real-world road routing
  //
  // Separate from the existing graph-based A* routing.
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getRealWorldRoute({
    required double startLatitude,
    required double startLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    String mode = 'drive',
  }) async {
    _validateCoordinates(
      latitude: startLatitude,
      longitude: startLongitude,
    );

    _validateCoordinates(
      latitude: destinationLatitude,
      longitude: destinationLongitude,
    );

    final response = await http.post(
      Uri.parse('$baseUrl/api/routes/real-world/'),
      headers: await _headers(),
      body: jsonEncode({
        'start_lat': startLatitude,
        'start_lon': startLongitude,
        'destination_lat': destinationLatitude,
        'destination_lon': destinationLongitude,
        'mode': mode,
      }),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'Real-world route API');
  }

  // ---------------------------------------------------------------------------
  // POIs
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getPois() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/pois/'),
      headers: await _headers(),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'POI API');
  }

  // ---------------------------------------------------------------------------
  // Place information
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getPlaceInfo(
    String placeId,
  ) async {
    final encodedPlaceId = Uri.encodeComponent(placeId);

    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/places/$encodedPlaceId/info/',
      ),
      headers: await _headers(),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'Place information API');
  }

  // ---------------------------------------------------------------------------
  // AI Place Intelligence
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> generatePlaceIntelligence({
    required String placeId,
  }) async {
    final encodedPlaceId = Uri.encodeComponent(placeId);

    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/places/$encodedPlaceId/ai/',
      ),
      headers: await _headers(),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'Place intelligence API');
  }

  // ---------------------------------------------------------------------------
  // Reviews
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getReviews({
    required String targetType,
    required String targetId,
  }) async {
    final encodedType = Uri.encodeComponent(targetType);
    final encodedId = Uri.encodeComponent(targetId);

    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/reviews/$encodedType/$encodedId/',
      ),
      headers: await _headers(),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'Reviews API');
  }

  static Future<Map<String, dynamic>> createReview({
    required String targetType,
    required String targetId,
    required int rating,
    required String comment,
    String? authorName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/reviews/'),
      headers: await _headers(),
      body: jsonEncode({
        'target_type': targetType,
        'target_id': targetId,
        'rating': rating,
        'comment': comment,
        if (authorName != null && authorName.isNotEmpty)
          'author_name': authorName,
      }),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'Create review API');
  }

  // ---------------------------------------------------------------------------
  // Nearby places
  //
  // Existing nearby search is preserved.
  // ---------------------------------------------------------------------------

  static Future<List<dynamic>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    String? category,
  }) async {
    _validateCoordinates(
      latitude: latitude,
      longitude: longitude,
    );

    if (!radiusKm.isFinite || radiusKm <= 0) {
      throw ArgumentError.value(
        radiusKm,
        'radiusKm',
        'Radius must be a positive finite number.',
      );
    }

    final queryParameters = <String, String>{
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'radius': radiusKm.toString(),
    };

    if (category != null && category.isNotEmpty) {
      queryParameters['category'] = category;
    }

    final uri = Uri.parse(
      '$baseUrl/api/places/nearby/',
    ).replace(
      queryParameters: queryParameters,
    );

    final response = await http.get(
      uri,
      headers: await _headers(),
    );

    _checkOk(response);

    final body = _asMap(
      _decodeJson(response),
      context: 'Nearby places API',
    );

    return _asList(
      body['data'] ?? [],
      context: 'Nearby places data',
    );
  }

  // ---------------------------------------------------------------------------
  // Featured destinations — district-aware Home recommendations
  //
  // Expected response:
  // {
  //   "success": true,
  //   "district": "...",
  //   "city": "...",
  //   "state": "...",
  //   "destinations": [...]
  // }
  //
  // This is separate from Nearby Places.
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getFeaturedDestinations({
    required double latitude,
    required double longitude,
  }) async {
    _validateCoordinates(
      latitude: latitude,
      longitude: longitude,
    );

    final uri = Uri.parse(
      '$baseUrl/api/featured-destinations/',
    ).replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
      },
    );

    debugPrint('[Featured API] GET $uri');

    final response = await http.get(
      uri,
      headers: await _headers(),
    );

    debugPrint(
      '[Featured API] HTTP status: ${response.statusCode}',
    );

    _checkOk(response);

    final body = _asMap(
      _decodeJson(response),
      context: 'Featured destinations API',
    );

    final destinations = body['destinations'];

    if (destinations is! List) {
      throw const FormatException(
        'Featured destinations API response is missing '
        'a valid destinations list.',
      );
    }

    final destinationMaps = destinations
        .whereType<Map>()
        .map(
          (destination) =>
              Map<String, dynamic>.from(destination),
        )
        .toList();

    debugPrint(
      '[Featured API] District: ${body['district']}',
    );
    debugPrint(
      '[Featured API] City: ${body['city']}',
    );
    debugPrint(
      '[Featured API] Destination count: ${destinationMaps.length}',
    );
    debugPrint(
      '[Featured API] Destination names: '
      '${destinationMaps.map((destination) => destination['name']).toList()}',
    );

    return body;
  }

  // ---------------------------------------------------------------------------
  // Hotels
  // ---------------------------------------------------------------------------

  static Future<List<dynamic>> getHotels({
    String? area,
    double? maxPrice,
    double? latitude,
    double? longitude,
    double radiusKm = 10,
  }) async {
    if ((latitude == null) != (longitude == null)) {
      throw ArgumentError(
        'Latitude and longitude must either both be supplied or both omitted.',
      );
    }

    if (latitude != null && longitude != null) {
      _validateCoordinates(
        latitude: latitude,
        longitude: longitude,
      );

      if (!radiusKm.isFinite || radiusKm <= 0) {
        throw ArgumentError.value(
          radiusKm,
          'radiusKm',
          'Radius must be a positive finite number.',
        );
      }
    }

    final queryParameters = <String, String>{
      if (area != null && area.isNotEmpty) 'area': area,
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (latitude != null && longitude != null) ...{
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'radius_km': radiusKm.toString(),
      },
    };

    final uri = Uri.parse(
      '$baseUrl/api/hotels/',
    ).replace(
      queryParameters: queryParameters,
    );

    final response = await http.get(
      uri,
      headers: await _headers(),
    );

    _checkOk(response);

    final body = _asMap(
      _decodeJson(response),
      context: 'Hotels API',
    );

    return _asList(
      body['data'] ?? [],
      context: 'Hotels data',
    );
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
    final response = await http.post(
      Uri.parse('$baseUrl/api/bookings/'),
      headers: await _headers(),
      body: jsonEncode({
        'hotel_id': hotelId,
        'guest_name': guestName,
        'room_type': roomType,
        'check_in': checkIn,
        'check_out': checkOut,
      }),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'Create booking API');
  }

  static Future<List<dynamic>> getBookingHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/bookings/history/'),
      headers: await _headers(),
    );

    _checkOk(response);

    final body = _asMap(
      _decodeJson(response),
      context: 'Booking history API',
    );

    return _asList(
      body['data'] ?? [],
      context: 'Booking history data',
    );
  }

  // ---------------------------------------------------------------------------
  // Emergency contacts
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> createEmergencyContact({
    required String name,
    required String phone,
    String relationship = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/emergency-contacts/'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'relationship': relationship,
      }),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(
      body,
      context: 'Create emergency contact API',
    );
  }

  static Future<List<dynamic>> getEmergencyContacts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/emergency-contacts/list/'),
      headers: await _headers(),
    );

    _checkOk(response);

    final body = _asMap(
      _decodeJson(response),
      context: 'Emergency contacts API',
    );

    return _asList(
      body['data'] ?? [],
      context: 'Emergency contacts data',
    );
  }

  // ---------------------------------------------------------------------------
  // SOS
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> triggerSos({
    double? latitude,
    double? longitude,
  }) async {
    if ((latitude == null) != (longitude == null)) {
      throw ArgumentError(
        'Latitude and longitude must either both be supplied or both omitted.',
      );
    }

    if (latitude != null && longitude != null) {
      _validateCoordinates(
        latitude: latitude,
        longitude: longitude,
      );
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/sos/trigger/'),
      headers: await _headers(),
      body: jsonEncode({
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      }),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'Trigger SOS API');
  }

  // ---------------------------------------------------------------------------
  // SOS — Get currently active event
  //
  // Returns the complete response object. The response may contain
  // data: null when there is no active SOS.
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getActiveSos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/sos/active/'),
      headers: await _headers(),
    );

    _checkOk(response);

    return _asMap(
      _decodeJson(response),
      context: 'Active SOS API',
    );
  }

  static Future<Map<String, dynamic>> activateSos(
    String eventId,
  ) async {
    final encodedEventId = Uri.encodeComponent(eventId);

    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/sos/$encodedEventId/activate/',
      ),
      headers: await _headers(),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'Activate SOS API');
  }

  static Future<Map<String, dynamic>> resolveSos(
    String eventId,
  ) async {
    final encodedEventId = Uri.encodeComponent(eventId);

    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/sos/$encodedEventId/resolve/',
      ),
      headers: await _headers(),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'Resolve SOS API');
  }

  // ---------------------------------------------------------------------------
  // Itinerary
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> createItinerary({
    required String title,
    required List<Map<String, dynamic>> stops,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/itinerary/create/'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'stops': stops,
      }),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'Create itinerary API');
  }

  static Future<List<Map<String, dynamic>>> getItineraries() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/itinerary/'),
      headers: await _headers(),
    );

    _checkOk(response);

    final body = _asMap(
      _decodeJson(response),
      context: 'Itineraries API',
    );

    final items = _asList(
      body['data'] ?? [],
      context: 'Itineraries data',
    );

    return items
        .map(
          (item) => _asMap(
            item,
            context: 'Itinerary item',
          ),
        )
        .toList();
  }

  static Future<Map<String, dynamic>> getItinerary(
    String itineraryId,
  ) async {
    final encodedItineraryId = Uri.encodeComponent(itineraryId);

    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/itinerary/$encodedItineraryId/',
      ),
      headers: await _headers(),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'Itinerary details API');
  }

  // ---------------------------------------------------------------------------
  // Preferences
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> savePreferences({
    required List<String> interests,
    required String budget,
    required String travelStyle,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/preferences/'),
      headers: await _headers(),
      body: jsonEncode({
        'interests': interests,
        'budget': budget,
        'travel_style': travelStyle,
      }),
    );

    _checkOk(response);

    final body = _decodeJson(response);

    return _dataMap(body, context: 'Save preferences API');
  }

  // ---------------------------------------------------------------------------
  // Recommendations
  // ---------------------------------------------------------------------------

  static Future<List<dynamic>> getRecommendations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/recommendations/'),
      headers: await _headers(),
    );

    _checkOk(response);

    final body = _asMap(
      _decodeJson(response),
      context: 'Recommendations API',
    );

    return _asList(
      body['data'] ?? [],
      context: 'Recommendations data',
    );
  }

  // ---------------------------------------------------------------------------
  // WorldCompanion AI Assistant
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> sendAssistantMessage(
    String message, {
    List<Map<String, dynamic>>? conversation,
    bool confirmed = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/assistant/'),
      headers: await _headers(),
      body: jsonEncode({
        'message': message,
        'confirmed': confirmed,
        if (conversation != null) 'conversation': conversation,
      }),
    );

    _checkOk(response);

    return _asMap(
      _decodeJson(response),
      context: 'WorldCompanion Assistant API',
    );
  }
}
