import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  String? _profileError;
  String? _profileSuccess;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final profile = await AuthService.getProfile();
    if (mounted) {
      if (profile != null) {
        _usernameController.text = profile['username']?.toString() ?? '';
        _emailController.text = profile['email']?.toString() ?? '';
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
      _profileError = null;
      _profileSuccess = null;
    });

    final result = await AuthService.updateProfile(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (result.containsKey('success')) {
          _profileSuccess = 'Profil mis à jour avec succès';
        } else {
          _profileError = result['error']?.toString() ?? 'Erreur inconnue';
        }
      });
    }
  }

  Future<void> _changePassword() async {
    setState(() {
      _passwordError = null;
      _passwordSuccess = null;
    });

    final oldPwd = _oldPasswordController.text;
    final newPwd = _newPasswordController.text;
    final confirmPwd = _confirmPasswordController.text;

    if (oldPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
      setState(() => _passwordError = 'Veuillez remplir tous les champs');
      return;
    }
    if (newPwd.length < 6) {
      setState(
        () => _passwordError = 'Le nouveau mot de passe doit faire au moins 6 caractères',
      );
      return;
    }
    if (newPwd != confirmPwd) {
      setState(
        () => _passwordError = 'Les mots de passe ne correspondent pas',
      );
      return;
    }

    setState(() => _isSaving = true);

    final result = await AuthService.changePassword(
      oldPassword: oldPwd,
      newPassword: newPwd,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (result.containsKey('success')) {
          _passwordSuccess = 'Mot de passe changé avec succès';
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        } else {
          _passwordError = result['error']?.toString() ?? 'Erreur inconnue';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + nom
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.primaryColor.withAlpha(40),
                    child: Text(
                      _usernameController.text.isNotEmpty
                          ? _usernameController.text[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _usernameController.text,
                    style: AppTheme.headlineLarge(),
                  ),
                  Text(
                    _emailController.text,
                    style: AppTheme.subtitle(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Section Informations ──────────────────────────
            _sectionTitle('Informations du compte', Icons.person_outline),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _usernameController,
              label: 'Nom d\'utilisateur',
              icon: Icons.person,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),

            // Messages profil
            if (_profileError != null) ...[
              const SizedBox(height: 8),
              _messageBox(_profileError!, isError: true),
            ],
            if (_profileSuccess != null) ...[
              const SizedBox(height: 8),
              _messageBox(_profileSuccess!, isError: false),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text(
                  'Sauvegarder',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // ── Section Mot de passe ──────────────────────────
            _sectionTitle('Changer le mot de passe', Icons.lock_outline),
            const SizedBox(height: 12),

            _buildPasswordField(
              controller: _oldPasswordController,
              label: 'Mot de passe actuel',
              visible: _showOldPassword,
              onToggle: () =>
                  setState(() => _showOldPassword = !_showOldPassword),
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _newPasswordController,
              label: 'Nouveau mot de passe',
              visible: _showNewPassword,
              onToggle: () =>
                  setState(() => _showNewPassword = !_showNewPassword),
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirmer le nouveau mot de passe',
              visible: _showConfirmPassword,
              onToggle: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),

            // Messages mot de passe
            if (_passwordError != null) ...[
              const SizedBox(height: 8),
              _messageBox(_passwordError!, isError: true),
            ],
            if (_passwordSuccess != null) ...[
              const SizedBox(height: 8),
              _messageBox(_passwordSuccess!, isError: false),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _changePassword,
                icon: const Icon(Icons.lock_reset),
                label: const Text(
                  'Changer le mot de passe',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.accentColor,
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(title, style: AppTheme.headlineSmall()),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
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
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
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
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _messageBox(String message, {required bool isError}) {
    final color = isError ? AppTheme.dangerColor : AppTheme.successColor;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}