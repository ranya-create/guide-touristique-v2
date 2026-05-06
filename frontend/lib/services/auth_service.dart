import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8000/api/users';
  static const _storage = FlutterSecureStorage();

  // Inscription
  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur de connexion: $e'};
    }
  }

  // Connexion
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('access') && data.containsKey('refresh')) {
          await _storage.write(key: 'access_token', value: data['access']);
          await _storage.write(key: 'refresh_token', value: data['refresh']);
          await _storage.write(key: 'username', value: username);
          return {'success': true};
        }
      }

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return {
        'success': false,
        'error':
            data['detail'] ?? 'Nom d\'utilisateur ou mot de passe incorrect',
      };
    } on SocketException {
      return {
        'success': false,
        'error': 'Pas de connexion internet. Vérifiez votre réseau.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Impossible de se connecter. Veuillez réessayer.',
      };
    }
  }

  // Déconnexion
  static Future<void> logout() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  // Vérifie si connecté
  static Future<bool> isLoggedIn() async {
    try {
      final token = await _storage.read(key: 'access_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Récupère le token
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: 'access_token');
    } catch (e) {
      return null;
    }
  }

  // Récupère le username sauvegardé localement
  static Future<String?> getUsername() async {
    try {
      return await _storage.read(key: 'username');
    } catch (e) {
      return null;
    }
  }

  // Refresh access token en silence
  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('access')) {
          await _storage.write(key: 'access_token', value: data['access']);
          return true;
        }
      }

      await logout();
      return false;
    } on SocketException {
      return false;
    } catch (e) {
      await logout();
      return false;
    }
  }

  static Future<http.Response?> authorizedRequest(
    Future<http.Response> Function(String token) request,
  ) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await request(token);
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (!refreshed) return response;

        final newToken = await getToken();
        if (newToken == null) return response;
        return request(newToken);
      }
      return response;
    } on SocketException {
      return null;
    } catch (e) {
      return null;
    }
  }

  // Récupère le profil complet depuis l'API
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await authorizedRequest((token) {
        return http.get(
          Uri.parse('$baseUrl/profile/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      });

      if (response != null && response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // Met à jour le profil (username, email)
  static Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? email,
  }) async {
    try {
      final response = await authorizedRequest((token) {
        final body = <String, String>{};
        if (username != null && username.isNotEmpty) {
          body['username'] = username;
        }
        if (email != null && email.isNotEmpty) {
          body['email'] = email;
        }
        return http.patch(
          Uri.parse('$baseUrl/profile/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );
      });

      if (response == null) {
        return {'error': 'Impossible de se connecter. Vérifiez votre réseau.'};
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (username != null) {
          await _storage.write(key: 'username', value: username);
        }
        return {'success': true, ...data};
      }
      return {'error': data['detail'] ?? 'Erreur lors de la mise à jour'};
    } on SocketException {
      return {'error': 'Pas de connexion internet. Vérifiez votre réseau.'};
    } catch (e) {
      return {'error': 'Erreur de connexion: $e'};
    }
  }

  // Change le mot de passe
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await authorizedRequest((token) {
        return http.post(
          Uri.parse('$baseUrl/change-password/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'old_password': oldPassword,
            'new_password': newPassword,
          }),
        );
      });

      if (response == null) {
        return {'error': 'Impossible de se connecter. Vérifiez votre réseau.'};
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'error': data['detail'] ?? 'Mot de passe actuel incorrect'};
    } on SocketException {
      return {'error': 'Pas de connexion internet. Vérifiez votre réseau.'};
    } catch (e) {
      return {'error': 'Erreur de connexion: $e'};
    }
  }

  // Vide toutes les données
  static Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
