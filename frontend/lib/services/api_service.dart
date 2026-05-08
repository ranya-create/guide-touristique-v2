import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'cache_service.dart';

enum NetworkErrorType {
  noInternet,
  serverDown,
  timeout,
  unauthorized,
  serverError,
  unknown,
}

class NetworkException implements Exception {
  final NetworkErrorType type;
  final String message;
  const NetworkException(this.type, this.message);

  @override
  String toString() => message;

  String get userMessage {
    switch (type) {
      case NetworkErrorType.noInternet:
        return 'Pas de connexion internet. Vérifiez votre réseau.';
      case NetworkErrorType.serverDown:
        return 'Le serveur est indisponible. Réessayez plus tard.';
      case NetworkErrorType.timeout:
        return 'La connexion est trop lente. Réessayez.';
      case NetworkErrorType.unauthorized:
        return 'Session expirée. Veuillez vous reconnecter.';
      case NetworkErrorType.serverError:
        return 'Erreur serveur. Réessayez dans quelques instants.';
      case NetworkErrorType.unknown:
        return 'Une erreur inattendue s\'est produite.';
    }
  }
}

NetworkException _handleException(dynamic e) {
  if (e is SocketException) {
    return const NetworkException(
      NetworkErrorType.noInternet,
      'Pas de connexion internet',
    );
  }
  if (e is TimeoutException) {
    return const NetworkException(NetworkErrorType.timeout, 'Délai dépassé');
  }
  if (e is NetworkException) return e;
  return NetworkException(NetworkErrorType.unknown, e.toString());
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const Duration _timeout = Duration(seconds: 30);
  static String? lastError;

  static void _setError(String message) {
    lastError = message;
    debugPrint(message);
  }

  static void _clearError() {
    lastError = null;
  }

  static Future<http.Response?> _safeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_timeout);
    } on SocketException catch (e) {
      _setError('Pas de connexion internet. Vérifiez votre réseau.');
      throw _handleException(e);
    } on TimeoutException catch (e) {
      _setError('La connexion est trop lente. Réessayez.');
      throw _handleException(e);
    } catch (e) {
      _setError('Erreur réseau : $e');
      throw _handleException(e);
    }
  }

  static Future<http.Response?> _authorizedRequest(
    Future<http.Response> Function(String token) request,
  ) async {
    try {
      final response = await AuthService.authorizedRequest(request);
      if (response == null) {
        _setError('Non connecté ou impossible de contacter le serveur.');
        return null;
      }
      if (response.statusCode == 401) {
        _setError('Session expirée, reconnectez-vous.');
      }
      return response;
    } on SocketException catch (e) {
      _setError('Pas de connexion internet. Vérifiez votre réseau.');
      throw _handleException(e);
    } catch (e) {
      _setError('Erreur réseau : $e');
      throw _handleException(e);
    }
  }

  static Future<dynamic> _get(String url, {bool auth = false}) async {
    final uri = Uri.parse(url);
    try {
      final response = auth
          ? await _authorizedRequest((token) {
              return http.get(
                uri,
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              );
            })
          : await _safeRequest(() => http.get(uri));

      if (response == null) return null;
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      if (response.statusCode >= 500) {
        throw const NetworkException(
          NetworkErrorType.serverDown,
          'Serveur indisponible. Réessayez plus tard.',
        );
      }
      if (response.statusCode == 401) {
        throw const NetworkException(
          NetworkErrorType.unauthorized,
          'Session expirée. Veuillez vous reconnecter.',
        );
      }
    } on NetworkException catch (e) {
      _setError(e.userMessage);
      rethrow;
    }
    return null;
  }

  static Future<dynamic> _post(
    String url,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final uri = Uri.parse(url);
    try {
      final response = auth
          ? await _authorizedRequest((token) {
              return http.post(
                uri,
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode(body),
              );
            })
          : await _safeRequest(
              () => http.post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(body),
              ),
            );

      if (response == null) return null;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      if (response.statusCode >= 500) {
        throw const NetworkException(
          NetworkErrorType.serverError,
          'Erreur serveur. Réessayez dans quelques instants.',
        );
      }
      if (response.statusCode == 401) {
        throw const NetworkException(
          NetworkErrorType.unauthorized,
          'Session expirée. Veuillez vous reconnecter.',
        );
      }
    } on NetworkException catch (e) {
      _setError(e.userMessage);
      rethrow;
    }
    return null;
  }


  static Future<bool> submitRating({
  required dynamic lieuId,
  required double rating,
  }) async {
  _clearError();
  try {
    // On utilise la méthode _post interne avec auth: true
    // Le endpoint dépend de votre backend (ex: /ratings/ ou /notes/)
    final data = await _post(
      '$baseUrl/notes/', 
      {
        'lieu': lieuId,
        'note': rating,
      },
      auth: true,
    );
    
    return data != null;
  } catch (e) {
    debugPrint('Erreur submitRating: $e');
    return false;
  }
}

  static Future<List<dynamic>> getLieux() async {
    _clearError();

    final cachedLieux = await CacheService.getCachedLieux();
    if (cachedLieux != null && cachedLieux.isNotEmpty) {
      _refreshLieuxCache();
      return cachedLieux;
    }

    try {
      final data = await _get('$baseUrl/lieux/');
      if (data is List<dynamic>) {
        await CacheService.cacheLieux(data);
        return data;
      }
    } catch (_) {}

    _setError('Pas de connexion internet et aucun cache disponible.');
    return [];
  }

  static Future<List<dynamic>> rechercherLieux(String query) async {
    _clearError();
    final uri = Uri.parse(
      '$baseUrl/lieux/',
    ).replace(queryParameters: {'search': query});

    try {
      final data = await _get(uri.toString());
      if (data is List<dynamic> && data.isNotEmpty) {
        return data;
      }
    } catch (_) {}

    final cachedLieux = await CacheService.getCachedLieux();
    if (cachedLieux != null && cachedLieux.isNotEmpty) {
      final filtered = _filterLieux(cachedLieux, query);
      if (filtered.isNotEmpty) return filtered;
    }

    _setError('Aucun résultat trouvé pour "$query".');
    return [];
  }

  static Future<List<dynamic>> getCategories() async {
    _clearError();
    try {
      final data = await _get('$baseUrl/categories/');
      if (data is List<dynamic>) return data;
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getFavoris(String token) async {
    _clearError();
    try {
      final data = await _get('$baseUrl/favoris/', auth: true);
      if (data is List<dynamic>) return data;
    } catch (_) {}
    return [];
  }

  static Future<bool> toggleFavori(dynamic lieuId, String token) async {
    _clearError();
    try {
      final data = await _post('$baseUrl/favoris/', {
        'lieu': lieuId,
      }, auth: true);
      return data != null;
    } catch (_) {
      return false;
    }
  }

  static Future<String> getWikipediaDescription(String nom) async {
    _clearError();

    try {
      final response = await _safeRequest(
        () => http.get(
          Uri.parse(
            'https://fr.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(nom)}',
          ),
        ),
      );

      if (response != null && response.statusCode == 200) {
        return json.decode(response.body)['extract'] ?? 'Pas de description.';
      }
    } catch (_) {}

    return 'Impossible de charger la description. Vérifiez votre connexion.';
  }

  static Future<Map<String, dynamic>> generateItinerary({
    required String origin,
    required String destination,
  }) async {
    try {
      final data = await _post('$baseUrl/itinerary/', {
        'origin': origin,
        'destination': destination,
      });
      if (data is Map<String, dynamic>) return data;
      return {};
    } catch (e) {
      debugPrint('Erreur generateItinerary: $e');
      return {};
    }
  }

  static Future<String?> sendChatMessage({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    try {
      final data = await _post('$baseUrl/chatbot/', {
        'message': message,
        'history': history,
      });
      return data is Map<String, dynamic> ? data['response']?.toString() : null;
    } catch (e) {
      debugPrint('Erreur chatbot: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> generateAiProgram({
    required String location,
    required String budget,
    required String duration,
    required List<String> preferences,
  }) async {
    try {
      final data = await _post('$baseUrl/ai-planner/', {
        'location': location,
        'budget': budget,
        'duration': duration,
        'preferences': preferences,
      });
      if (data is Map<String, dynamic> && data['status'] == 'success') {
        return Map<String, dynamic>.from(data['program'] ?? {});
      }
      debugPrint('Erreur ai-planner: ${data?['error'] ?? 'Réponse invalide'}');
      return null;
    } catch (e) {
      debugPrint('Erreur ai-planner: $e');
      return null;
    }
  }

  static Future<void> _refreshLieuxCache() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/lieux/'));
      if (response.statusCode == 200) {
        final lieux = json.decode(response.body);
        await CacheService.cacheLieux(lieux);
      }
    } catch (e) {
      debugPrint('Erreur rafraîchissement cache: $e');
    }
  }

  static String _normalizeText(String text) {
    final normalized = text.trim().toLowerCase();
    return normalized
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c');
  }

  static List<dynamic> _filterLieux(List<dynamic> lieux, String query) {
    final normalizedQuery = _normalizeText(query);
    return lieux.where((lieu) {
      final nom = _normalizeText(lieu['nom']?.toString() ?? '');
      final description = _normalizeText(lieu['description']?.toString() ?? '');
      final adresse = _normalizeText(lieu['adresse']?.toString() ?? '');
      final categorie = _normalizeText(lieu['categorie_nom']?.toString() ?? '');
      return nom.contains(normalizedQuery) ||
          description.contains(normalizedQuery) ||
          adresse.contains(normalizedQuery) ||
          categorie.contains(normalizedQuery);
    }).toList();
  }
}
