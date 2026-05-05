import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../dashboard/dashboard_page.dart';
import '../widgets/professional_background.dart';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;

  late Animation<Offset> _moveAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLogin = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyController = TextEditingController();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();

    _moveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _moveAnimation = Tween<Offset>(begin: const Offset(3.0, 0.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _moveController, curve: Curves.easeOutCubic),
    );

    _rotateController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _runAnimationSequence();
  }

  void _runAnimationSequence() async {
    await _moveController.forward();
    await _rotateController.forward();
    if (mounted) {
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _moveController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);

    if (_isLogin) {
      // --- LOGIN RÉEL ---
      final result = await _apiService.login(
          _emailController.text, _passwordController.text);

      if (result['success']) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const DashboardPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    } else {
      // --- INSCRIPTION RÉELLE ---
      final userData = {
        'email': _emailController.text,
        'password': _passwordController.text,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'companyName': _companyController.text,
      };

      final result = await _apiService.register(userData);

      if (result['success']) {
        setState(() => _isLogin = true); // Basculer vers login après succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscription réussie ! Connectez-vous.'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ProfessionalBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SlideTransition(
                position: _moveAnimation, 
                child: RotationTransition(
                  turns: _rotateAnimation, 
                  child: Text('alt.', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1.2, color: isDark ? Colors.white : Colors.black))
                )
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text('votre assistante personnelle', style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    const Text('Gérer votre vie pro et perso en un seul endroit', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 40),
                    if (!_isLogin) ...[
                      _buildField(_firstNameController, 'Prénom', Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildField(_lastNameController, 'Nom', Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildField(_companyController, 'Raison Sociale (Optionnel)', Icons.business_outlined),
                      const SizedBox(height: 12),
                    ],
                    _buildField(_emailController, t.email, Icons.email_outlined),
                    const SizedBox(height: 12),
                    _buildField(_passwordController, t.password, Icons.lock_outline, isPassword: true),
                    if (!_isLogin) ...[
                      const SizedBox(height: 12),
                      _buildField(_confirmPasswordController, 'Confirmer le mot de passe', Icons.lock_reset, isPassword: true),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, 
                      height: 55, 
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleAuth, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF49F6C7) : Colors.black, 
                          foregroundColor: isDark ? Colors.black : Colors.white, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ), 
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : Text(_isLogin ? t.login : 'S\'inscrire', style: const TextStyle(fontWeight: FontWeight.bold))
                      )
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: Text(_isLogin ? 'Continuer avec Google' : 'S\'inscrire avec Google'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark ? Colors.transparent : Colors.white70,
                        minimumSize: const Size(double.infinity, 50), 
                        foregroundColor: isDark ? Colors.white : Colors.black87, 
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin), 
                      child: Text(_isLogin ? '${t.dontHaveAccount} ${t.register}' : 'Déjà inscrit ? Se connecter', style: TextStyle(color: isDark ? const Color(0xFF49F6C7) : Colors.black))
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller, 
      obscureText: isPassword, 
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, size: 18, color: isDark ? const Color(0xFF49F6C7) : Colors.black54), 
        filled: true, 
        fillColor: isDark ? const Color(0xFF232435) : Colors.white.withOpacity(0.8), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.black12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
      )
    );
  }
}
