import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AiProgramScreen extends StatefulWidget {
  const AiProgramScreen({super.key});

  @override
  State<AiProgramScreen> createState() => _AiProgramScreenState();
}

class _AiProgramScreenState extends State<AiProgramScreen> {
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _durationController = TextEditingController();

  final List<String> _allPreferences = [
    'Culture',
    'Histoire',
    'Nature',
    'Gastronomie',
    'Architecture',
    'Plages',
    'Randonnée',
    'Shopping',
    'Musées',
    'Mosquées',
  ];
  final List<String> _selectedPreferences = [];

  bool _isLoading = false;
  Map<String, dynamic>? _program;
  String? _error;

  @override
  void dispose() {
    _locationController.dispose();
    _budgetController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _generateProgram() async {
    final location = _locationController.text.trim();
    final budget = _budgetController.text.trim();
    final duration = _durationController.text.trim();

    if (location.isEmpty || budget.isEmpty || duration.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs obligatoires');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _program = null;
    });

    try {
      final result = await ApiService.generateAiProgram(
        location: location,
        budget: budget,
        duration: duration,
        preferences: _selectedPreferences,
      );

      if (mounted) {
        setState(() {
          _program = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur : $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Programme IA', style: AppTheme.headlineLarge()),
                  Text(
                    'Généré par Llama 3.3',
                    style: AppTheme.subtitle(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Champ ville
          _buildTextField(
            controller: _locationController,
            label: 'Ville ou destination',
            hint: 'Ex: Marrakech, Fès, Chefchaouen...',
            icon: Icons.location_city,
          ),
          const SizedBox(height: 12),

          // Budget et durée côte à côte
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _budgetController,
                  label: 'Budget (MAD)',
                  hint: 'Ex: 500',
                  icon: Icons.account_balance_wallet,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _durationController,
                  label: 'Durée (jours)',
                  hint: 'Ex: 3',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Préférences
          Text('Préférences (optionnel)', style: AppTheme.headlineSmall()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allPreferences.map((pref) {
              final selected = _selectedPreferences.contains(pref);
              return FilterChip(
                label: Text(pref),
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedPreferences.add(pref);
                    } else {
                      _selectedPreferences.remove(pref);
                    }
                  });
                },
                selectedColor: AppTheme.primaryColor.withAlpha(50),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: selected ? AppTheme.primaryColor : Colors.grey[700],
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Bouton générer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateProgram,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isLoading ? 'Génération en cours...' : 'Générer mon programme',
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
          const SizedBox(height: 16),

          // Erreur
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.dangerColor.withAlpha(26),
                border: Border.all(color: AppTheme.dangerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.dangerColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.dangerColor),
                    ),
                  ),
                ],
              ),
            ),

          // Programme généré
          if (_program != null) ...[
            const SizedBox(height: 24),
            _buildProgram(_program!),
          ],

          // État vide
          if (!_isLoading && _program == null && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Renseignez vos préférences\npour générer un programme personnalisé',
                      textAlign: TextAlign.center,
                      style: AppTheme.subtitle(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgram(Map<String, dynamic> program) {
    final summary = program['summary']?.toString() ?? '';
    final days = program['days'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Résumé
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withAlpha(30),
                AppTheme.accentColor.withAlpha(20),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withAlpha(80),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary,
                  style: AppTheme.bodyText().copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          '${days.length} jour(s) de programme',
          style: AppTheme.headlineSmall(),
        ),
        const SizedBox(height: 12),

        // Jours
        ...days.asMap().entries.map((entry) {
          final dayIndex = entry.key;
          final day = entry.value as Map<String, dynamic>;
          final activities = day['activities'] as List<dynamic>? ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête du jour
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white.withAlpha(50),
                        child: Text(
                          '${dayIndex + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Jour ${dayIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${activities.length} activité(s)',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Activités
                ...activities.asMap().entries.map((actEntry) {
                  final act = actEntry.value as Map<String, dynamic>;
                  final cost = act['cost'];
                  final isLast =
                      actEntry.key == activities.length - 1;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: Colors.grey.withAlpha(50),
                              ),
                            ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                act['name']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (act['description'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  act['description'].toString(),
                                  style: AppTheme.subtitle(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (cost != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$cost MAD',
                              style: const TextStyle(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
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
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }
}