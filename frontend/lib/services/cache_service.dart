import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService {
  static const String _lieuxCacheKey = 'cached_lieux';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const Duration _cacheDuration = Duration(
    hours: 24,
  ); // Cache valide 24h

  // Sauvegarder les lieux en cache
  static Future<void> cacheLieux(List<dynamic> lieux) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await prefs.setString(_lieuxCacheKey, jsonEncode(lieux));
    await prefs.setInt(_cacheTimestampKey, timestamp);
  }

  // Récupérer les lieux du cache
  static Future<List<dynamic>?> getCachedLieux() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_lieuxCacheKey);
    final timestamp = prefs.getInt(_cacheTimestampKey);

    if (cachedData == null || timestamp == null) {
      return null;
    }

    // Vérifier si le cache est encore valide
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (now.difference(cacheTime) > _cacheDuration) {
      // Cache expiré, supprimer
      await clearCache();
      return null;
    }

    try {
      return jsonDecode(cachedData) as List<dynamic>;
    } catch (e) {
      // Erreur de parsing, supprimer le cache corrompu
      await clearCache();
      return null;
    }
  }

  // Vérifier si le cache existe et est valide
  static Future<bool> hasValidCache() async {
    final cachedLieux = await getCachedLieux();
    return cachedLieux != null && cachedLieux.isNotEmpty;
  }

  // Supprimer le cache
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lieuxCacheKey);
    await prefs.remove(_cacheTimestampKey);
  }
}
