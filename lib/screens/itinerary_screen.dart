import 'package:flutter/material.dart';
import '../services/itinerary_service.dart';
import '../widgets/step_card.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final ItineraryService _service = ItineraryService();

  List<Map<String, dynamic>> _steps = [];
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _generateItinerary() async {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez remplir le départ et la destination';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _steps = [];
    });

    try {
      final steps = await _service.getItinerary(
        origin: _originController.text,
        destination: _destinationController.text,
      );
      setState(() {
        _steps = steps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur : $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinéraire touristique'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Champ départ
            TextField(
              controller: _originController,
              decoration: const InputDecoration(
                labelText: 'Point de départ',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Champ destination
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                prefixIcon: Icon(Icons.flag),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Bouton générer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateItinerary,
                icon: const Icon(Icons.directions),
                label: const Text('Générer l\'itinéraire'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Message erreur
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),

            // Chargement
            if (_isLoading)
              const CircularProgressIndicator(),

            // Liste des étapes
            Expanded(
              child: ListView.builder(
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return StepCard(
                    stepNumber: index + 1,
                    step: _steps[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}