import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'cache_service.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
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
      return await request();
    } on SocketException {
      _setError('Pas de connexion internet. Vérifiez votre réseau.');
    } catch (e) {
      _setError('Erreur réseau : $e');
    }
    return null;
  }

  static Future<http.Response?> _authorizedRequest(
    Future<http.Response> Function(String token) request,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) {
      _setError('Non connecté.');
      return null;
    }

    final response = await _safeRequest(() => request(token));
    if (response == null) return null;
    if (response.statusCode == 401) {
      final refreshed = await AuthService.refreshAccessToken();
      if (!refreshed) {
        _setError('Session expirée, reconnectez-vous.');
        return response;
      }

      final newToken = await AuthService.getToken();
      if (newToken == null) return response;
      return _safeRequest(() => request(newToken));
    }
    return response;
  }

  static Future<List<dynamic>> getLieux() async {
    _clearError();

    // Essayer de récupérer du cache d'abord
    final cachedLieux = await CacheService.getCachedLieux();
    if (cachedLieux != null && cachedLieux.isNotEmpty) {
      // Retourner le cache immédiatement pour une expérience hors-ligne fluide
      // Mais essayer de rafraîchir en arrière-plan
      _refreshLieuxCache();
      return cachedLieux;
    }

    // Pas de cache ou cache vide, faire la requête réseau
    final response = await _safeRequest(
      () => http.get(Uri.parse('$baseUrl/lieux/')),
    );
    if (response == null) {
      _setError('Pas de connexion internet et aucun cache disponible.');
      return [];
    }

    if (response.statusCode == 200) {
      final lieux = json.decode(response.body);
      // Sauvegarder en cache pour utilisation hors-ligne future
      await CacheService.cacheLieux(lieux);
      return lieux;
    }

    _setError('Serveur indisponible. Réessayez plus tard.');
    return [];
  }

  // Méthode pour rafraîchir le cache en arrière-plan
  static Future<void> _refreshLieuxCache() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/lieux/'));
      if (response.statusCode == 200) {
        final lieux = json.decode(response.body);
        await CacheService.cacheLieux(lieux);
      }
    } catch (e) {
      // Ignorer les erreurs en arrière-plan
      debugPrint('Erreur rafraîchissement cache: $e');
    }
  }

  // Vérifier si l'app fonctionne en mode hors-ligne
  static Future<bool> isOfflineMode() async {
    return await CacheService.hasValidCache();
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

  static Future<List<dynamic>> rechercherLieux(String query) async {
    _clearError();
    final uri = Uri.parse(
      '$baseUrl/lieux/',
    ).replace(queryParameters: {'search': query});
    final response = await _safeRequest(() => http.get(uri));
    if (response != null && response.statusCode == 200) {
      final results = json.decode(response.body) as List<dynamic>;
      if (results.isNotEmpty) {
        return results;
      }
    }

    // Si la recherche en ligne échoue ou ne donne rien, filtrer localement le cache
    final cachedLieux = await CacheService.getCachedLieux();
    if (cachedLieux != null && cachedLieux.isNotEmpty) {
      final filtered = _filterLieux(cachedLieux, query);
      if (filtered.isNotEmpty) {
        return filtered;
      }
    }

    if (response == null) {
      _setError('Pas de connexion internet. Vérifiez votre réseau.');
    } else {
      _setError('Aucun résultat trouvé pour "$query".');
    }
    return [];
  }

  static Future<List<dynamic>> getFavoris(String token) async {
    _clearError();
    final response = await _authorizedRequest((authToken) {
      return http.get(
        Uri.parse('$baseUrl/favoris/'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );
    });

    if (response == null) return [];
    if (response.statusCode == 200) return json.decode(response.body);
    if (response.statusCode >= 500) {
      _setError('Serveur indisponible. Réessayez plus tard.');
    }
    return [];
  }

  static Future<List<dynamic>> getCategories() async {
    _clearError();
    final response = await _safeRequest(
      () => http.get(Uri.parse('$baseUrl/categories/')),
    );
    if (response == null) return [];
    if (response.statusCode == 200) return json.decode(response.body);
    _setError('Serveur indisponible. Réessayez plus tard.');
    return [];
  }

  // CORRECTION : lieuId accepte dynamic pour éviter l'erreur int/String
  static Future<bool> toggleFavori(dynamic lieuId, String token) async {
    _clearError();
    final response = await _authorizedRequest((authToken) {
      return http.post(
        Uri.parse('$baseUrl/favoris/'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'lieu': lieuId}),
      );
    });

    if (response == null) return false;
    if (response.statusCode == 200 || response.statusCode == 201) return true;
    if (response.statusCode >= 500) {
      _setError('Serveur indisponible. Réessayez plus tard.');
    }
    return false;
  }

  static Future<String> getWikipediaDescription(String nom) async {
    _clearError();
    final response = await _safeRequest(
      () => http.get(
        Uri.parse(
          'https://fr.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(nom)}',
        ),
      ),
    );

    if (response == null) {
      return 'Impossible de charger la description. Vérifiez votre connexion.';
    }
    if (response.statusCode == 200) {
      return json.decode(response.body)['extract'] ?? 'Pas de description.';
    }
    _setError('Impossible de charger la description.');
    return 'Description non disponible.';
  }
}
