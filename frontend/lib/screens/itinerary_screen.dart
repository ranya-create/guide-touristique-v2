import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/route_service.dart';
import '../theme/app_theme.dart';
import '../widgets/step_card.dart';
import '../widgets/modern_widgets.dart';

class ItineraryScreen extends StatefulWidget {
  final String? initialOrigin;
  final String? initialDestination;
  final VoidCallback? onViewRoute;

  const ItineraryScreen({
    super.key,
    this.initialOrigin,
    this.initialDestination,
    this.onViewRoute,
  });

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  late TextEditingController _originController;
  final TextEditingController _destinationController = TextEditingController();

  List<Map<String, dynamic>> _steps = [];
  List<LatLng> _routePoints = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String? _lastRequestHash;

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController(text: widget.initialOrigin ?? '');
    if (widget.initialDestination != null) {
      _destinationController.text = widget.initialDestination!;
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  /// Valide les champs d'entrée
  String? _validateInputs() {
    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();

    if (origin.isEmpty) {
      return 'Veuillez saisir un point de départ';
    }
    if (destination.isEmpty) {
      return 'Veuillez saisir une destination';
    }
    if (origin.length > 255 || destination.length > 255) {
      return 'Le texte est trop long (max 255 caractères)';
    }
    if (origin.toLowerCase() == destination.toLowerCase()) {
      return 'Le départ et la destination doivent être différents';
    }

    return null;
  }

  /// Génère un hash pour vérifier les doublons
  String _getRequestHash(String origin, String destination) {
    return '${origin.trim()}|${destination.trim()}';
  }

  Future<void> _generateItinerary() async {
    // Valider les entrées
    final validationError = _validateInputs();
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
        _steps = [];
      });
      return;
    }

    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();
    final requestHash = _getRequestHash(origin, destination);

    // Vérifier s'il y a déjà une requête en cours pour la même destination
    if (_lastRequestHash == requestHash && _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _steps = [];
      _lastRequestHash = requestHash;
    });

    try {
      final data = await ApiService.generateItinerary(
        origin: origin,
        destination: destination,
      );

      final steps = <Map<String, dynamic>>[];
      if (data.containsKey('steps') && data['steps'] is List) {
        steps.addAll(
          (data['steps'] as List).map(
            (step) => Map<String, dynamic>.from(step as Map<String, dynamic>),
          ),
        );
      }

      final routePoints = <LatLng>[];
      if (data.containsKey('route') && data['route'] is List) {
        for (final rawPoint in data['route'] as List) {
          if (rawPoint is Map) {
            final lat = double.tryParse(rawPoint['lat']?.toString() ?? '');
            final lon = double.tryParse(rawPoint['lon']?.toString() ?? '');
            if (lat != null && lon != null) {
              routePoints.add(LatLng(lat, lon));
            }
          } else if (rawPoint is List && rawPoint.length >= 2) {
            final lat = double.tryParse(rawPoint[0]?.toString() ?? '');
            final lon = double.tryParse(rawPoint[1]?.toString() ?? '');
            if (lat != null && lon != null) {
              routePoints.add(LatLng(lat, lon));
            }
          }
        }
      }

      if (routePoints.isNotEmpty) {
        RouteService.updateRoute(routePoints);
      } else {
        RouteService.clearRoute();
      }

      if (mounted) {
        setState(() {
          _steps = steps;
          _routePoints = routePoints;
          _isLoading = false;
          _errorMessage = steps.isEmpty ? 'Aucun itinéraire trouvé' : '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur : $e';
          _isLoading = false;
          _steps = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('planifier R'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Planifier votre itinéraire',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Découvrez la meilleure route entre deux lieux',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Champ départ
                ModernTextField(
                  controller: _originController,
                  label: 'Point de départ',
                  hint: 'Exemple: Fès, Marrakech...',
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: AppTheme.primaryColor,
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),

                // Champ destination
                ModernTextField(
                  controller: _destinationController,
                  label: 'Destination',
                  hint: 'Exemple: Casablanca, Essaouira...',
                  prefixIcon: const Icon(
                    Icons.flag,
                    color: AppTheme.primaryColor,
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 24),

                // Bouton générer
                ModernButton(
                  text: _isLoading
                      ? 'Génération en cours...'
                      : 'Générer l\'itinéraire',
                  onPressed: _isLoading ? null : _generateItinerary,
                  isLoading: _isLoading,
                  icon: _isLoading ? null : Icons.directions,
                ),
                const SizedBox(height: 20),

                // Message erreur ou succès
                if (_errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _steps.isNotEmpty
                          ? AppTheme.successColor.withAlpha(26)
                          : AppTheme.dangerColor.withAlpha(26),
                      border: Border.all(
                        color: _steps.isNotEmpty
                            ? AppTheme.successColor
                            : AppTheme.dangerColor,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _steps.isNotEmpty ? Icons.check_circle : Icons.error,
                          color: _steps.isNotEmpty
                              ? AppTheme.successColor
                              : AppTheme.dangerColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: _steps.isNotEmpty
                                  ? AppTheme.successColor
                                  : AppTheme.dangerColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Liste des étapes
                if (_steps.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Étapes du trajet',
                      style: AppTheme.headlineSmall(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      return StepCard(
                        stepNumber: index + 1,
                        step: _steps[index],
                      );
                    },
                  ),
                ],
                if (_routePoints.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Aperçu de la route',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onViewRoute,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: _routePoints.first,
                              initialZoom: 11,
                              interactionOptions: const InteractionOptions(),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.guide_touristique',
                              ),
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: _routePoints,
                                    strokeWidth: 5,
                                    color: AppTheme.primaryColor.withAlpha(220),
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _routePoints.first,
                                    width: 44,
                                    height: 44,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.successColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(64),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.my_location,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Marker(
                                    point: _routePoints.last,
                                    width: 44,
                                    height: 44,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(64),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.flag,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (widget.onViewRoute != null)
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(
                                    (0.4 * 255).round(),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.map,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Appuyez pour ouvrir la carte',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.onViewRoute != null)
                    ModernButton(
                      text: 'Voir la route sur la carte',
                      onPressed: widget.onViewRoute,
                      icon: Icons.map,
                    ),
                ],

                // Message vide
                if (!_isLoading && _steps.isEmpty && _errorMessage.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Planifiez votre itinéraire touristique',
                          style: AppTheme.headlineSmall().copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
