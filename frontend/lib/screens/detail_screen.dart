import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/itinerary_service.dart';
import '../theme/app_theme.dart';
import 'itinerary_screen.dart';
import 'package:share_plus/share_plus.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> lieu;
  const DetailScreen({super.key, required this.lieu});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String _wikiDescription = '';
  bool _isLoadingWiki = true;
  bool _isFavori = false;
  bool _isGeneratingItinerary = false;
  double _userRating = 0; // Note de l'utilisateur (0-5)
  bool _isSubmittingRating = false;

  @override
  void initState() {
    super.initState();
    _loadWikipedia();
    _checkIfFavori();
  }

  @override
  void dispose() {
    ItineraryService.clearCache();
    super.dispose();
  }

  Future<void> _loadWikipedia() async {
    final description = await ApiService.getWikipediaDescription(
      widget.lieu['nom'].toString(),
    );
    if (mounted) {
      setState(() {
        _wikiDescription = description;
        _isLoadingWiki = false;
      });
    }
  }

  Future<void> _checkIfFavori() async {
    final token = await AuthService.getToken();
    if (token != null) {
      final favoris = await ApiService.getFavoris(token);
      if (mounted) {
        setState(() {
          // CORRECTION : comparaison en String pour éviter int vs String
          _isFavori = favoris.any(
            (f) => f['lieu'].toString() == widget.lieu['id'].toString(),
          );
        });
      }
    }
  }

  Future<void> _toggleFavori() async {
    final token = await AuthService.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour gérer vos favoris')),
      );
      return;
    }

    // CORRECTION : passage de l'id directement (dynamic)
    final success = await ApiService.toggleFavori(widget.lieu['id'], token);

    if (!mounted) return;

    if (success) {
      setState(() {
        _isFavori = !_isFavori;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavori ? 'Ajouté aux favoris' : 'Retiré des favoris',
          ),
        ),
      );
    }
  }

  Future<void> _generateItineraryFromHere() async {
    setState(() {
      _isGeneratingItinerary = true;
    });

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ItineraryScreen(initialLocation: widget.lieu['nom'].toString()),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isGeneratingItinerary = false;
        });
      }
    });
  }

  // Partager le lieu
  Future<void> _shareLieu() async {
    final lieuName = widget.lieu['nom']?.toString() ?? 'Lieu touristique';
    final categorie = widget.lieu['categorie_nom']?.toString() ?? '';
    final description = widget.lieu['description']?.toString() ?? '';

    final shareText =
        '''
Découvrez $lieuName${categorie.isNotEmpty ? ' ($categorie)' : ''}

${description.isNotEmpty ? '$description\n\n' : ''}Partagé depuis Guide Touristique Maroc
    '''
            .trim();

    try {
      await Share.share(shareText, subject: lieuName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erreur lors du partage')));
      }
    }
  }

  // Soumettre une note
  Future<void> _submitRating(double rating) async {
    final token = await AuthService.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour noter ce lieu')),
      );
      return;
    }

    setState(() {
      _isSubmittingRating = true;
    });

    // TODO: Implémenter l'API pour soumettre les notes
    // Pour l'instant, on simule avec un délai
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _userRating = rating;
        _isSubmittingRating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note de $rating étoile(s) enregistrée')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lieu['nom'].toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isFavori ? Icons.favorite : Icons.favorite_border,
              color: _isFavori ? AppTheme.dangerColor : Colors.white70,
            ),
            onPressed: _toggleFavori,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du lieu
            Stack(
              children: [
                if (widget.lieu['image'] != null &&
                    widget.lieu['image'].toString().isNotEmpty)
                  Image.network(
                    widget.lieu['image'].toString(),
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 280,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.location_on,
                        size: 64,
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.lieu['nom'].toString(),
                          style: AppTheme.headlineLarge(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Catégorie
                  if (widget.lieu['categorie_nom'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(38),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.lieu['categorie_nom'].toString(),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Adresse
                  if (widget.lieu['adresse'] != null &&
                      widget.lieu['adresse'].toString().isNotEmpty)
                    Card(
                      elevation: 0,
                      color: AppTheme.lightBackgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppTheme.dangerColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.lieu['adresse'].toString(),
                                style: AppTheme.bodyText(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Description
                  if (widget.lieu['description'] != null &&
                      widget.lieu['description'].toString().isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('À propos', style: AppTheme.headlineSmall()),
                        const SizedBox(height: 8),
                        Text(
                          widget.lieu['description'].toString(),
                          style: AppTheme.bodyText().copyWith(height: 1.6),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Wikipedia
                  Text(
                    'Informations historiques',
                    style: AppTheme.headlineSmall(),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingWiki)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_wikiDescription.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Aucune information Wikipedia disponible',
                        style: AppTheme.subtitle(),
                      ),
                    )
                  else
                    Text(
                      _wikiDescription,
                      style: AppTheme.bodyText().copyWith(height: 1.6),
                    ),

                  const SizedBox(height: 24),

                  // Section note puis partage
                  Text('Votre note', style: AppTheme.headlineSmall()),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      final starRating = index + 1;
                      return IconButton(
                        onPressed: _isSubmittingRating
                            ? null
                            : () => _submitRating(starRating.toDouble()),
                        icon: Icon(
                          starRating <= _userRating
                              ? Icons.star
                              : Icons.star_border,
                          color: AppTheme.warningColor,
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _shareLieu,
                      icon: const Icon(Icons.share),
                      label: const Text('Partager'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Bouton itinéraire
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingItinerary
                          ? null
                          : _generateItineraryFromHere,
                      icon: _isGeneratingItinerary
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.directions),
                      label: Text(
                        _isGeneratingItinerary
                            ? 'Chargement...'
                            : 'Créer un itinéraire',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
