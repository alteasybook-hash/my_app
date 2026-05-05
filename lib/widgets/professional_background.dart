import 'package:flutter/material.dart';

class ProfessionalBackground extends StatelessWidget {
  final Widget child;
  final bool showShapes;

  const ProfessionalBackground({
    super.key,
    required this.child,
    this.showShapes = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
      body: Stack(
        children: [
          if (!isDark && showShapes) ...[
            // Cercle Dégradé Haut Droite
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF49F6C7).withOpacity(0.4),
                      const Color(0xFF3AB5FF).withOpacity(0.2),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            
            // Forme subtile en bas à gauche
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3AB5FF).withOpacity(0.15),
                      const Color(0xFF49F6C7).withOpacity(0.05),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // L'application par dessus
          SafeArea(
            bottom: false, // Correction : On retire le padding du bas pour descendre la barre de navigation
            child: child,
          ),
        ],
      ),
    );
  }
}
