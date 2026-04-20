import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ItineraryService {
  String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000/api';
    }
    return 'http://127.0.0.1:5000/api';
  }

  Future<List<Map<String, dynamic>>> getItinerary({
    required String origin,
    required String destination,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/itinerary/');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'origin': origin,
          'destination': destination,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List steps = data['steps'];
        return steps.map((step) => Map<String, dynamic>.from(step)).toList();
      } else {
        throw Exception('Erreur serveur : ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Impossible de contacter le serveur : $e');
    }
  }
}