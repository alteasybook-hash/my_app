import 'package:flutter/material.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _rotateController;
  late AnimationController _textController;

  late Animation<Offset> _moveAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Courbe personnalisée pour un effet "Premium"
    const proCurve = Cubic(0.2, 1.0, 0.3, 1.0);

    // 1. Contrôleur pour le mouvement (Arrivée de la droite)
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _moveAnimation = Tween<Offset>(
      begin: const Offset(3.0, 0.0), // Part de très loin à droite
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _moveController,
      curve: proCurve,
    ));

    // 2. Contrôleur pour la rotation (Tourne une fois)
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate( // 1 tour complet
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );

    // 3. Contrôleur pour le texte (Apparition douce)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  void _startSequence() async {
    // Étape 1 : Arrivée de la droite
    await _moveController.forward();
    
    // Étape 2 : Rotation
    await _rotateController.forward();
    
    // Étape 3 : Apparition des textes
    await _textController.forward();

    // Étape 4 : Pause et redirection vers Login
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _moveController.dispose();
    _rotateController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation du LOGO alt.
            SlideTransition(
              position: _moveAnimation,
              child: RotationTransition(
                turns: _rotateAnimation,
                child: const Text(
                  'alt.',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: -2,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // Animation des TEXTES
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const Text(
                    'Votre assistante personnelle',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Gérer votre vie pro et perso en un seul endroit',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
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
