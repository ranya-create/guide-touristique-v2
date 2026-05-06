import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import 'map_screen.dart';
import 'itinerary_screen.dart';
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

  final List<Widget> _screens = [
    const MapScreen(),
    const ItineraryScreen(),
    const FavoritesScreen(),
    const ListsScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = [
    'Carte',
    'Itinéraire',
    'Mes Favoris',
    'Mes Listes',
    'Mon Profil',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername();
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
    final bool showAppBar = _currentIndex != 0;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(_titles[_currentIndex]),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                // Avatar cliquable dans l'AppBar (hors carte)
                if (_currentIndex != 4)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = 4),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withAlpha(50),
                        child: Text(
                          _username.isNotEmpty
                              ? _username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Déconnexion',
                  onPressed: _logout,
                ),
              ],
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: AppBar(
                backgroundColor: AppTheme.primaryColor,
                elevation: 0,
              ),
            ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 16,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Carte',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.directions),
            label: 'Itinéraire',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoris',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Listes',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 12,
              backgroundColor: _currentIndex == 4
                  ? AppTheme.primaryColor
                  : Colors.grey.shade300,
              child: Text(
                _username.isNotEmpty ? _username[0].toUpperCase() : '?',
                style: TextStyle(
                  color: _currentIndex == 4 ? Colors.white : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}