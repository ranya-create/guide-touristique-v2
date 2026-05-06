import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<dynamic> _favorites = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    final token = await AuthService.getToken();
    if (token != null) {
      _token = token;
      final data = await ApiService.getFavoris(token);
      if (mounted) {
        setState(() {
          _favorites = data;
          _errorMessage = ApiService.lastError ?? '';
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFavorite(int lieuId) async {
    if (_token == null) return;

    final success = await ApiService.toggleFavori(lieuId, _token!);
    if (success && mounted) {
      setState(() {
        _favorites.removeWhere((f) => f['lieu'] == lieuId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Retiré des favoris')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: AppTheme.headlineSmall().copyWith(
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vérifiez votre connexion ou réessayez plus tard.',
                    textAlign: TextAlign.center,
                    style: AppTheme.subtitle(),
                  ),
                ],
              ),
            ),
          )
        : _token == null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Connectez-vous pour voir vos favoris',
                  style: AppTheme.headlineSmall().copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : _favorites.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Aucun favori pour le moment',
                  style: AppTheme.headlineSmall().copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez des lieux à vos favoris',
                  style: AppTheme.subtitle(),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: _favorites.length,
            itemBuilder: (context, index) {
              final fav = _favorites[index];
              final lieuId = fav['lieu'];

              return FutureBuilder<Map<String, dynamic>>(
                future: _getLieuDetails(lieuId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final lieu = snapshot.data!;
                  final hasImage =
                      lieu['image'] != null &&
                      lieu['image'].toString().isNotEmpty;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(lieu: lieu),
                          ),
                        ).then((_) {
                          _loadFavorites();
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasImage)
                              Stack(
                                children: [
                                  Image.network(
                                    lieu['image'],
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 160,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => _removeFavorite(lieuId),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.dangerColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(77),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: const Icon(
                                          Icons.favorite,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Container(
                                height: 160,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Icon(
                                        Icons.location_on,
                                        size: 48,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => _removeFavorite(lieuId),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppTheme.dangerColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(
                                                  77,
                                                ),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: const Icon(
                                            Icons.favorite,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lieu['nom'],
                                    style: AppTheme.headlineSmall(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (lieu['categorie_nom'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withAlpha(
                                          38,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        lieu['categorie_nom'],
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (lieu['categorie_nom'] != null)
                                    const SizedBox(height: 8),
                                  if (lieu['adresse'] != null)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: AppTheme.dangerColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            lieu['adresse'],
                                            style: AppTheme.subtitle(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
  }

  Future<Map<String, dynamic>> _getLieuDetails(int lieuId) async {
    final allLieux = await ApiService.getLieux();
    return allLieux.firstWhere(
      (lieu) => lieu['id'] == lieuId,
      orElse: () => {'id': lieuId, 'nom': 'Lieu inconnu'},
    );
  }
}
