import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';
import 'search_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<Marker> _markers = [];
  List<dynamic> _allLieux = []; // Tous les lieux chargés
  bool _isLoading = true;
  LatLng _currentPosition = const LatLng(33.5731, -7.5898);
  dynamic _selectedLieu;
  bool _showSearchResults = false;
  List<dynamic> _searchResults = [];

  // IDs des lieux favoris de l'utilisateur
  Set<String> _favorisIds = {};

  // Filtrage par catégories
  Set<String> _selectedCategories = {}; // Catégories sélectionnées
  List<String> _availableCategories = []; // Toutes les catégories disponibles

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadFavoris();
    await _loadMarkers();
    await _getCurrentLocation();
    if (mounted) setState(() => _isLoading = false);
  }

  // Charge les favoris pour colorer les marqueurs
  Future<void> _loadFavoris() async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final favoris = await ApiService.getFavoris(token);
    if (mounted) {
      setState(() {
        _favorisIds = favoris
            .map((f) => f['lieu']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur GPS: $e');
    }
  }

  Future<void> _loadMarkers() async {
    try {
      final lieux = await ApiService.getLieux();
      _allLieux = lieux; // Stocker tous les lieux

      // Extraire les catégories uniques
      final categories =
          lieux
              .map((lieu) => lieu['categorie_nom']?.toString() ?? '')
              .where((cat) => cat.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      if (mounted) {
        setState(() {
          _availableCategories = categories;
          // Si aucune catégorie n'est sélectionnée, afficher toutes
          if (_selectedCategories.isEmpty) {
            _selectedCategories = categories.toSet();
          }
        });
      }

      _filterAndDisplayMarkers();
    } catch (e) {
      debugPrint('ERREUR marqueurs: $e');
    }
  }

  // Filtre et affiche les marqueurs selon les catégories sélectionnées
  void _filterAndDisplayMarkers() {
    final List<Marker> markers = [];

    for (final lieu in _allLieux) {
      final categorie = lieu['categorie_nom']?.toString() ?? '';
      if (!_selectedCategories.contains(categorie)) continue;

      final latStr = lieu['latitude']?.toString() ?? '';
      final lngStr = lieu['longitude']?.toString() ?? '';
      if (latStr.isEmpty || lngStr.isEmpty) continue;

      final lat = double.tryParse(latStr);
      final lng = double.tryParse(lngStr);
      if (lat == null || lng == null) continue;

      final isFavori = _favorisIds.contains(lieu['id']?.toString() ?? '');

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 45,
          height: 45,
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedLieu = lieu);
              _mapController.move(LatLng(lat, lng), 15);
            },
            child: _buildMarker(isFavori: isFavori),
          ),
        ),
      );
    }

    if (mounted) setState(() => _markers = markers);
  }

  // Bascule la sélection d'une catégorie
  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
      // Si aucune catégorie n'est sélectionnée, sélectionner toutes
      if (_selectedCategories.isEmpty) {
        _selectedCategories = _availableCategories.toSet();
      }
    });
    _filterAndDisplayMarkers();
  }

  // Marqueur bleu normal ou rouge étoile pour les favoris
  Widget _buildMarker({required bool isFavori}) {
    return Container(
      decoration: BoxDecoration(
        color: isFavori ? AppTheme.dangerColor : AppTheme.primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isFavori ? AppTheme.dangerColor : AppTheme.primaryColor)
                .withAlpha(120),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isFavori ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Icon(
        isFavori ? Icons.favorite : Icons.location_on,
        color: Colors.white,
        size: 22,
      ),
    );
  }

  Future<void> _searchLieux(String query) async {
    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }

    try {
      final results = await ApiService.rechercherLieux(query);
      if (!mounted) return;

      if (ApiService.lastError != null && ApiService.lastError!.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiService.lastError!)));
      }

      setState(() {
        _searchResults = results;
        _showSearchResults = true;
      });
    } catch (e) {
      debugPrint('Erreur recherche: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erreur de recherche.')));
      }
    }
  }

  void _selectLieuFromSearch(dynamic lieu) {
    final lat = double.tryParse(lieu['latitude']?.toString() ?? '');
    final lng = double.tryParse(lieu['longitude']?.toString() ?? '');
    if (lat == null || lng == null) return;

    _mapController.move(LatLng(lat, lng), 15);
    setState(() {
      _selectedLieu = lieu;
      _showSearchResults = false;
      _searchController.clear();
    });
  }

  // Ouvre la page recherche complète
  void _openFullSearch() {
    final query = _searchController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          initialQuery: query.isEmpty ? null : query,
          initialResults: _searchResults.isEmpty ? null : _searchResults,
        ),
      ),
    ).then((selectedLieu) {
      if (selectedLieu != null && mounted) {
        // Un lieu a été sélectionné depuis SearchScreen
        final lat = double.tryParse(selectedLieu['latitude']?.toString() ?? '');
        final lng = double.tryParse(
          selectedLieu['longitude']?.toString() ?? '',
        );
        if (lat != null && lng != null) {
          // Centrer la carte
          _mapController.move(LatLng(lat, lng), 15);

          setState(() {
            _selectedLieu = selectedLieu;
            _searchController.clear();
            _showSearchResults = false;
            // Ajouter la catégorie du lieu si elle n'est pas sélectionnée
            final categorie = selectedLieu['categorie_nom']?.toString() ?? '';
            if (categorie.isNotEmpty && !_selectedCategories.contains(categorie)) {
              _selectedCategories.add(categorie);
            }
          });
          
          // Recalculer les marqueurs pour inclure le nouveau lieu
          _filterAndDisplayMarkers();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Carte principale
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 12,
                    onTap: (_, _) {
                      // Ferme les résultats si on tape sur la carte
                      if (_showSearchResults) {
                        setState(() => _showSearchResults = false);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.guide_touristique',
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),

                // Barre de recherche en haut
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Champ de recherche
                        TextField(
                          controller: _searchController,
                          onChanged: _searchLieux,
                          decoration: InputDecoration(
                            hintText: 'Rechercher un lieu...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _showSearchResults = false;
                                        _searchResults = [];
                                      });
                                    },
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.tune,
                                      color: AppTheme.primaryColor,
                                    ),
                                    tooltip: 'Recherche avancée',
                                    onPressed: _openFullSearch,
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),

                        // Résultats de recherche inline
                        if (_showSearchResults && _searchResults.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            constraints: BoxConstraints(
                              maxHeight: 300,
                              maxWidth: MediaQuery.of(context).size.width - 24,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(26),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // En-tête avec nb résultats
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_searchResults.length} résultat(s)',
                                        style: AppTheme.subtitle(),
                                      ),
                                      TextButton(
                                        onPressed: _openFullSearch,
                                        child: const Text('Voir tout'),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                Flexible(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _searchResults.length,
                                    itemBuilder: (context, index) {
                                      final lieu = _searchResults[index];
                                      final isFavori = _favorisIds.contains(
                                        lieu['id']?.toString() ?? '',
                                      );
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: isFavori
                                              ? AppTheme.dangerColor.withAlpha(
                                                  30,
                                                )
                                              : AppTheme.primaryColor.withAlpha(
                                                  30,
                                                ),
                                          child: Icon(
                                            isFavori
                                                ? Icons.favorite
                                                : Icons.location_on,
                                            color: isFavori
                                                ? AppTheme.dangerColor
                                                : AppTheme.primaryColor,
                                            size: 18,
                                          ),
                                        ),
                                        title: Text(
                                          lieu['nom']?.toString() ??
                                              'Lieu sans nom',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          lieu['categorie_nom']?.toString() ??
                                              '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        onTap: () =>
                                            _selectLieuFromSearch(lieu),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Message "aucun résultat"
                        if (_showSearchResults && _searchResults.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(26),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Aucun résultat trouvé',
                                  style: AppTheme.subtitle(),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Boutons de filtrage par catégorie (bas)
                if (_availableCategories.isNotEmpty)
                  Positioned(
                    bottom: _selectedLieu != null ? 180 : 16,
                    left: 12,
                    right: 12,
                    child: SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _availableCategories.map((category) {
                          final isSelected = _selectedCategories.contains(
                            category,
                          );
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) => _toggleCategory(category),
                              backgroundColor: Colors.white,
                              selectedColor: AppTheme.primaryColor,
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                // Boutons d'action (haut droit)
                Positioned(
                  top: 70,
                  right: 12,
                  child: SafeArea(
                    child: Column(
                      children: [
                        FloatingActionButton(
                          mini: true,
                          heroTag: 'location',
                          onPressed: () async {
                            await _getCurrentLocation();
                            _mapController.move(_currentPosition, 14);
                            setState(() => _selectedLieu = null);
                          },
                          backgroundColor: AppTheme.primaryColor,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          mini: true,
                          heroTag: 'zoom_in',
                          onPressed: () => _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          ),
                          backgroundColor: Colors.white,
                          child: const Icon(
                            Icons.add,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          mini: true,
                          heroTag: 'zoom_out',
                          onPressed: () => _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          ),
                          backgroundColor: Colors.white,
                          child: const Icon(
                            Icons.remove,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Fiche du lieu sélectionné (bas)
                if (_selectedLieu != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, -2),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _selectedLieu['nom']
                                                      ?.toString() ??
                                                  'Lieu',
                                              style: AppTheme.headlineSmall(),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          // Badge favori
                                          if (_favorisIds.contains(
                                            _selectedLieu['id']?.toString() ??
                                                '',
                                          ))
                                            const Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Icon(
                                                Icons.favorite,
                                                color: AppTheme.dangerColor,
                                                size: 18,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedLieu['categorie_nom']
                                                ?.toString() ??
                                            '',
                                        style: AppTheme.subtitle(),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () =>
                                      setState(() => _selectedLieu = null),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_selectedLieu['description'] != null &&
                                _selectedLieu['description']
                                    .toString()
                                    .isNotEmpty)
                              Text(
                                _selectedLieu['description'].toString(),
                                style: AppTheme.bodyText(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DetailScreen(lieu: _selectedLieu),
                                      ),
                                    ).then((_) {
                                      // Recharger les favoris au retour
                                      _loadFavoris().then(
                                        (_) => _loadMarkers(),
                                      );
                                    }),
                                icon: const Icon(Icons.info),
                                label: const Text('Voir les détails'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
