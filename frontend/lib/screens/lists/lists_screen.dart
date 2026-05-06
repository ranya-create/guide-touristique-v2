import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../search_screen.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final Map<int, int> _categoryLieuCount = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final categories = await ApiService.getCategories();
      final lieux = await ApiService.getLieux();

      // Compter les lieux par catégorie
      final counts = <int, int>{};
      for (final lieu in lieux) {
        final catId = lieu['categorie'];
        if (catId != null) {
          counts[catId] = (counts[catId] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _categories = categories;
          _categoryLieuCount.addAll(counts);
          _errorMessage = ApiService.lastError ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              ApiService.lastError ?? 'Impossible de charger les catégories.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _filterByCategory(int categoryId, String categoryName) async {
    // Récupérer tous les lieux et filtrer par catégorie
    final allLieux = await ApiService.getLieux();
    final filtered = allLieux
        .where((lieu) => lieu['categorie'] == categoryId)
        .toList();

    if (!mounted) return;

    // Naviguer vers SearchScreen avec les résultats filtrés
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          initialResults: filtered,
          initialTitle: 'Catégorie: $categoryName',
        ),
      ),
    );
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
        : _categories.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Aucune catégorie disponible',
                  style: AppTheme.headlineSmall().copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final cat = _categories[index];
                    final catId = cat['id'] as int;
                    final count = _categoryLieuCount[catId] ?? 0;
                    final categoryName = cat['nom'] ?? 'Catégorie';

                    final categoryIcons = {
                      'Musée': Icons.museum,
                      'Parc': Icons.park,
                      'Monument': Icons.language,
                      'Église': Icons.place,
                      'Château': Icons.castle,
                      'Galerie': Icons.photo_library,
                      'Théâtre': Icons.theater_comedy,
                      'Bibliothèque': Icons.library_books,
                      'Zoo': Icons.pets,
                      'Parc d\'attractions': Icons.toys,
                    };

                    final icon = categoryIcons[categoryName] ?? Icons.category;

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: InkWell(
                        onTap: () => _filterByCategory(catId, categoryName),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withAlpha(
                                        77,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  icon,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    categoryName,
                                    textAlign: TextAlign.center,
                                    style: AppTheme.headlineSmall(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withAlpha(
                                        38,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$count lieu${count != 1 ? 'x' : ''}',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: _categories.length),
                ),
              ),
            ],
          );
  }
}
