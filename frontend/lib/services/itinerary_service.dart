import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ItineraryService {
  // Cache local des itinéraires
  static final Map<String, List<Map<String, dynamic>>> _cache = {};
  static const Duration _cacheDuration = Duration(hours: 1);
  static final Map<String, DateTime> _cacheTime = {};

  // Timeout des requêtes
  static const Duration _timeout = Duration(seconds: 30);

  String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    return 'http://10.0.2.2:8000/api';
  }

  /// Valide les entrées
  bool _validateInputs(String origin, String destination) {
    if (origin.trim().isEmpty || destination.trim().isEmpty) {
      return false;
    }
    if (origin.length > 255 || destination.length > 255) {
      return false;
    }
    return true;
  }

  /// Génère une clé de cache
  String _getCacheKey(String origin, String destination) {
    return '${origin.trim()}|${destination.trim()}';
  }

  /// Vérifie si le cache est valide
  bool _isCacheValid(String cacheKey) {
    final time = _cacheTime[cacheKey];
    if (time == null) return false;
    return DateTime.now().difference(time) < _cacheDuration;
  }

  Future<List<Map<String, dynamic>>> getItinerary({
    required String origin,
    required String destination,
  }) async {
    // Validation
    if (!_validateInputs(origin, destination)) {
      throw Exception('Origine et destination requises (max 255 caractères)');
    }

    final cacheKey = _getCacheKey(origin, destination);

    // Vérifier le cache local
    if (_cache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final uri = Uri.parse('$baseUrl/itinerary/');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'origin': origin.trim(),
              'destination': destination.trim(),
            }),
          )
          .timeout(
            _timeout,
            onTimeout: () {
              throw TimeoutException('Serveur trop lent (30s)');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List steps = data['steps'] ?? [];
        final result = steps
            .map((step) => Map<String, dynamic>.from(step))
            .toList();

        // Mettre en cache
        _cache[cacheKey] = result;
        _cacheTime[cacheKey] = DateTime.now();

        return result;
      } else if (response.statusCode == 400) {
        throw Exception('Données invalides');
      } else if (response.statusCode == 500) {
        throw Exception('Erreur serveur');
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Impossible de contacter le serveur: $e');
    }
  }

  /// Vide le cache
  static void clearCache() {
    _cache.clear();
    _cacheTime.clear();
  }

  /// Vide le cache pour une clé spécifique
  static void clearCacheForRoute(String origin, String destination) {
    final key = '${origin.trim()}|${destination.trim()}';
    _cache.remove(key);
    _cacheTime.remove(key);
  }
}
