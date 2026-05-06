import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  final List<dynamic>? initialResults;
  final String? initialQuery;
  final String? initialTitle;

  const SearchScreen({
    super.key,
    this.initialResults,
    this.initialQuery,
    this.initialTitle,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<dynamic> _lieux = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final TextEditingController _controller = TextEditingController();

  Future<void> _rechercher(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    final results = query.isEmpty
        ? await ApiService.getLieux()
        : await ApiService.rechercherLieux(query);
    if (mounted) {
      setState(() {
        _lieux = results;
        _isLoading = false;
        _errorMessage = ApiService.lastError ?? '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery?.trim() ?? '';

    if (widget.initialResults != null) {
      _lieux = widget.initialResults!;
    } else if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _rechercher(widget.initialQuery!.trim());
    } else {
      _rechercher('');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche de lieux'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Rechercher un lieu, monument, musée...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.primaryColor,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _controller.clear();
                            setState(() {});
                            _rechercher('');
                          },
                        )
                      : null,
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
                ),
                onChanged: (value) {
                  setState(() {});
                  _rechercher(value.trim());
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_off,
                              size: 64,
                              color: Colors.grey,
                            ),
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
                  : _lieux.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun lieu trouvé',
                            style: AppTheme.headlineSmall().copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Essayez une autre recherche',
                            style: AppTheme.subtitle(),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      itemCount: _lieux.length,
                      itemBuilder: (context, index) {
                        final lieu = _lieux[index];
                        final hasImage =
                            lieu['image'] != null &&
                            lieu['image'].toString().isNotEmpty;
                        final description =
                            lieu['description']?.toString() ??
                            'Aucune description';

                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context, lieu);
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasImage)
                                    Container(
                                      height: 160,
                                      color: Colors.grey[300],
                                      child: Image.network(
                                        lieu['image'].toString(),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
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
                                    )
                                  else
                                    Container(
                                      height: 160,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.primaryColor.withAlpha(51),
                                            AppTheme.accentColor.withAlpha(26),
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.location_on,
                                        size: 56,
                                        color: AppTheme.primaryColor.withAlpha(
                                          128,
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                lieu['nom']?.toString() ??
                                                    'Lieu sans nom',
                                                style: AppTheme.headlineSmall(),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (lieu['categorie_nom'] != null)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  left: 8,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor
                                                      .withAlpha(38),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  lieu['categorie_nom']
                                                          ?.toString() ??
                                                      '',
                                                  style: const TextStyle(
                                                    color:
                                                        AppTheme.primaryColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (lieu['adresse'] != null &&
                                            lieu['adresse']
                                                .toString()
                                                .isNotEmpty)
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
                                                  lieu['adresse'].toString(),
                                                  style: AppTheme.subtitle(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (lieu['adresse'] != null)
                                          const SizedBox(height: 8),
                                        Text(
                                          description,
                                          style: AppTheme.bodyText(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
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
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
