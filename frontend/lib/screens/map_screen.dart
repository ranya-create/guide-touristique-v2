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
  List<dynamic> _allLieux = [];
  bool _isLoading = true;
  LatLng _currentPosition = const LatLng(33.5731, -7.5898);
  dynamic _selectedLieu;
  bool _showSearchResults = false;
  List<dynamic> _searchResults = [];
  Set<String> _favorisIds = {};
  Set<String> _selectedCategories = {};
  List<String> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    // Charger d'abord la carte, puis les données en arrière-plan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // GPS en parallèle avec les lieux (sans bloquer)
    _getCurrentLocationSilently();

    // Charger les lieux en premier (le plus important)
    await _loadMarkers();

    // Charger les favoris après
    await _loadFavoris();

    if (mounted) setState(() => _isLoading = false);
  }

  // GPS sans bloquer le chargement
  Future<void> _getCurrentLocationSilently() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low, // Plus rapide
        );
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
          _mapController.move(_currentPosition, 12);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadFavoris() async {
    try {
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
        _filterAndDisplayMarkers();
      }
    } catch (_) {}
  }

  Future<void> _loadMarkers() async {
    try {
      final lieux = await ApiService.getLieux();
      _allLieux = lieux;

      final categories =
          lieux
              .map((l) => l['categorie_nom']?.toString() ?? '')
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      if (mounted) {
        setState(() {
          _availableCategories = categories;
          _selectedCategories = categories.toSet();
        });
        _filterAndDisplayMarkers();
      }
    } catch (e) {
      debugPrint('ERREUR marqueurs: $e');
    }
  }

  void _filterAndDisplayMarkers() {
    final List<Marker> markers = [];

    for (final lieu in _allLieux) {
      final categorie = lieu['categorie_nom']?.toString() ?? '';
      if (_selectedCategories.isNotEmpty &&
          !_selectedCategories.contains(categorie)) {
        continue;
      }

      final lat = double.tryParse(lieu['latitude']?.toString() ?? '');
      final lng = double.tryParse(lieu['longitude']?.toString() ?? '');
      if (lat == null || lng == null) {
        continue;
      }

      final isFavori = _favorisIds.contains(lieu['id']?.toString() ?? '');

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
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

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        if (_selectedCategories.length > 1) {
          _selectedCategories.remove(category);
        }
      } else {
        _selectedCategories.add(category);
      }
    });
    _filterAndDisplayMarkers();
  }

  Widget _buildMarker({required bool isFavori}) {
    return Container(
      decoration: BoxDecoration(
        color: isFavori ? AppTheme.dangerColor : AppTheme.primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: isFavori ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Icon(
        isFavori ? Icons.favorite : Icons.location_on,
        color: Colors.white,
        size: 20,
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
      if (mounted) {
        setState(() {
          _searchResults = results;
          _showSearchResults = true;
        });
      }
    } catch (_) {}
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

  void _openFullSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    ).then((selectedLieu) {
      if (selectedLieu != null && mounted) {
        final lat = double.tryParse(selectedLieu['latitude']?.toString() ?? '');
        final lng = double.tryParse(
          selectedLieu['longitude']?.toString() ?? '',
        );
        if (lat != null && lng != null) {
          _mapController.move(LatLng(lat, lng), 15);
          setState(() {
            _selectedLieu = selectedLieu;
            _searchController.clear();
            _showSearchResults = false;
          });
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
      body: Stack(
        children: [
          // Carte principale — toujours visible
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 12,
              onTap: (_, _) {
                if (_showSearchResults) {
                  setState(() => _showSearchResults = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.guide_touristique',
              ),
              if (!_isLoading) MarkerLayer(markers: _markers),
            ],
          ),

          // Indicateur de chargement léger (pas bloquant)
          if (_isLoading)
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Chargement des lieux...',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Barre de recherche
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SafeArea(
              child: Column(
                children: [
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

                  // Résultats de recherche
                  if (_showSearchResults && _searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: BoxConstraints(
                        maxHeight: 250,
                        maxWidth: MediaQuery.of(context).size.width - 24,
                      ),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isFavori
                                        ? AppTheme.dangerColor.withAlpha(30)
                                        : AppTheme.primaryColor.withAlpha(30),
                                    child: Icon(
                                      isFavori
                                          ? Icons.favorite
                                          : Icons.location_on,
                                      color: isFavori
                                          ? AppTheme.dangerColor
                                          : AppTheme.primaryColor,
                                      size: 16,
                                    ),
                                  ),
                                  title: Text(
                                    lieu['nom']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    lieu['categorie_nom']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  onTap: () => _selectLieuFromSearch(lieu),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_showSearchResults && _searchResults.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_off,
                            color: Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text('Aucun résultat', style: AppTheme.subtitle()),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Filtres catégories (bas)
          if (_availableCategories.isNotEmpty && !_isLoading)
            Positioned(
              bottom: _selectedLieu != null ? 185 : 16,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _availableCategories.map((category) {
                    final isSelected = _selectedCategories.contains(category);
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
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) => _toggleCategory(category),
                        backgroundColor: Colors.white,
                        selectedColor: AppTheme.primaryColor,
                        checkmarkColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Boutons zoom + localisation
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
                      await _getCurrentLocationSilently();
                      _mapController.move(_currentPosition, 14);
                    },
                    backgroundColor: AppTheme.primaryColor,
                    child: const Icon(Icons.my_location, color: Colors.white),
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
                    child: const Icon(Icons.add, color: AppTheme.primaryColor),
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

          // Fiche lieu sélectionné
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
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedLieu['nom']?.toString() ?? '',
                                        style: AppTheme.headlineSmall(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_favorisIds.contains(
                                      _selectedLieu['id']?.toString() ?? '',
                                    ))
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.favorite,
                                          color: AppTheme.dangerColor,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  _selectedLieu['categorie_nom']?.toString() ??
                                      '',
                                  style: AppTheme.subtitle(),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () =>
                                setState(() => _selectedLieu = null),
                          ),
                        ],
                      ),
                      if (_selectedLieu['description'] != null &&
                          _selectedLieu['description'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _selectedLieu['description'].toString(),
                            style: AppTheme.bodyText(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                                _loadFavoris().then(
                                  (_) => _filterAndDisplayMarkers(),
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
