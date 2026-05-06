import 'package:flutter/material.dart';
import '../services/itinerary_service.dart';
import '../theme/app_theme.dart';
import '../widgets/step_card.dart';

class ItineraryScreen extends StatefulWidget {
  final String? initialLocation;
  const ItineraryScreen({super.key, this.initialLocation});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  late TextEditingController _originController;
  final TextEditingController _destinationController = TextEditingController();
  final ItineraryService _service = ItineraryService();

  List<Map<String, dynamic>> _steps = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String? _lastRequestHash;

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController(
      text: widget.initialLocation ?? '',
    );
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
      final steps = await _service.getItinerary(
        origin: origin,
        destination: destination,
      );

      if (mounted) {
        setState(() {
          _steps = steps;
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Titre
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Planifier votre itinéraire',
                    style: AppTheme.headlineLarge(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Découvrez la meilleure route entre deux lieux',
                    style: AppTheme.subtitle(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Champ départ
            TextField(
              controller: _originController,
              enabled: !_isLoading,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Point de départ',
                hintText: 'Exemple: Fès, Marrakech...',
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: AppTheme.primaryColor,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                errorText: _originController.text.length > 255
                    ? 'Texte trop long'
                    : null,
                counterText: '',
              ),
              maxLength: 255,
            ),
            const SizedBox(height: 16),

            // Champ destination
            TextField(
              controller: _destinationController,
              enabled: !_isLoading,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Destination',
                hintText: 'Exemple: Casablanca, Essaouira...',
                prefixIcon: const Icon(
                  Icons.flag,
                  color: AppTheme.primaryColor,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                errorText: _destinationController.text.length > 255
                    ? 'Texte trop long'
                    : null,
                counterText: '',
              ),
              maxLength: 255,
            ),
            const SizedBox(height: 24),

            // Bouton générer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateItinerary,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.directions),
                label: Text(
                  _isLoading
                      ? 'Génération en cours...'
                      : 'Générer l\'itinéraire',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Message erreur ou succès
            if (_errorMessage.isNotEmpty)
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
                  return StepCard(stepNumber: index + 1, step: _steps[index]);
                },
              ),
            ],

            // Message vide
            if (!_isLoading && _steps.isEmpty && _errorMessage.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions, size: 64, color: Colors.grey[300]),
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
        ),
      ),
    );
  }
}
