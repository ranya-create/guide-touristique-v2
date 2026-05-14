import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import 'map_screen.dart';
import 'itinerary_screen.dart';
import 'ai_program_screen.dart';
import 'chatbot_screen.dart';
import 'favorites/favorites_screen.dart';
import 'lists/lists_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _username = '';

  // Lazy loading : chaque écran n'est créé qu'au premier accès
  final Map<int, Widget> _cachedScreens = {};

  final List<String> _titles = [
    'Carte',
    'Itinéraire',
    'Programme IA',
    'Chatbot',
    'Mes Favoris',
    'Mes Listes',
    'Mon Profil',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  // Retourne l'écran depuis le cache, ou le crée s'il n'existe pas encore
  Widget _getScreen(int index) {
    if (!_cachedScreens.containsKey(index)) {
      _cachedScreens[index] = _buildScreen(index);
    }
    return _cachedScreens[index]!;
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const MapScreen();
      case 1:
        return ItineraryScreen(
          onViewRoute: () => setState(() => _currentIndex = 0),
        );
      case 2:
        return const AiProgramScreen();
      case 3:
        return const ChatbotScreen(); // Chargé seulement quand l'utilisateur clique
      case 4:
        return const FavoritesScreen();
      case 5:
        return const ListsScreen();
      case 6:
        return const ProfileScreen();
      default:
        return const SizedBox();
    }
  }

  Future<void> _loadUsername() async {
    final username = await AuthService.getUsername();
    if (mounted && username != null) {
      setState(() => _username = username);
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await AuthService.logout();
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              },
              child: const Text(
                'Déconnexion',
                style: TextStyle(color: AppTheme.dangerColor),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showAppBar = _currentIndex != 0 && _currentIndex != 3;
    final bool isProfileScreen = _currentIndex == 6;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(
                _titles[_currentIndex],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: AppTheme.textPrimary,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              actions: [
                if (!isProfileScreen)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = 6),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          gradient: _currentIndex == 6
                              ? AppTheme.primaryGradient
                              : null,
                          shape: BoxShape.circle,
                          color: _currentIndex == 6
                              ? null
                              : AppTheme.surfaceColor,
                          boxShadow: [
                            _currentIndex == 6
                                ? AppTheme.mediumShadow
                                : AppTheme.softShadow,
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.transparent,
                          child: Text(
                            _username.isNotEmpty
                                ? _username[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: _currentIndex == 6
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      Icons.logout_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    tooltip: 'Déconnexion',
                    onPressed: _logout,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.surfaceColor,
                      shadowColor: AppTheme.softShadow.color,
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
              ),
            ),

      // Lazy loading : seul l'écran actif est affiché,
      // les autres sont créés à la demande et mis en cache
      body: _getScreen(_currentIndex),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: [AppTheme.mediumShadow],
          border: Border(
            top: BorderSide(
              color: AppTheme.textMuted.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_currentIndex == 0 ? 8 : 6),
                decoration: BoxDecoration(
                  color: _currentIndex == 0
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _currentIndex == 0 ? Icons.map : Icons.map_outlined,
                  size: _currentIndex == 0 ? 24 : 22,
                ),
              ),
              label: 'Carte',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_currentIndex == 1 ? 8 : 6),
                decoration: BoxDecoration(
                  color: _currentIndex == 1
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _currentIndex == 1
                      ? Icons.directions
                      : Icons.directions_outlined,
                  size: _currentIndex == 1 ? 24 : 22,
                ),
              ),
              label: 'Itinéraire',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_currentIndex == 2 ? 8 : 6),
                decoration: BoxDecoration(
                  color: _currentIndex == 2
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _currentIndex == 2
                      ? Icons.auto_awesome
                      : Icons.auto_awesome_outlined,
                  size: _currentIndex == 2 ? 24 : 22,
                ),
              ),
              label: 'Programme IA',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_currentIndex == 3 ? 8 : 6),
                decoration: BoxDecoration(
                  color: _currentIndex == 3
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _currentIndex == 3
                      ? Icons.chat_bubble
                      : Icons.chat_bubble_outline,
                  size: _currentIndex == 3 ? 24 : 22,
                ),
              ),
              label: 'Chatbot',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_currentIndex == 4 ? 8 : 6),
                decoration: BoxDecoration(
                  color: _currentIndex == 4
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _currentIndex == 4 ? Icons.favorite : Icons.favorite_outline,
                  size: _currentIndex == 4 ? 24 : 22,
                ),
              ),
              label: 'Favoris',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_currentIndex == 5 ? 8 : 6),
                decoration: BoxDecoration(
                  color: _currentIndex == 5
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _currentIndex == 5
                      ? Icons.list_alt
                      : Icons.list_alt_outlined,
                  size: _currentIndex == 5 ? 24 : 22,
                ),
              ),
              label: 'Listes',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_currentIndex == 6 ? 8 : 6),
                decoration: BoxDecoration(
                  gradient: _currentIndex == 6
                      ? AppTheme.primaryGradient
                      : null,
                  color: _currentIndex == 6 ? null : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow:
                      _currentIndex == 6 ? [AppTheme.softShadow] : null,
                ),
                child: CircleAvatar(
                  radius: _currentIndex == 6 ? 12 : 11,
                  backgroundColor: Colors.transparent,
                  child: Text(
                    _username.isNotEmpty ? _username[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: _currentIndex == 6
                          ? Colors.white
                          : AppTheme.primaryColor,
                      fontSize: _currentIndex == 6 ? 12 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}