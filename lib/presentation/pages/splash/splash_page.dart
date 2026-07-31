import 'package:flutter/material.dart';

import '../../../core/config/app_theme.dart';

/// Pantalla de carga mostrada mientras se restaura la sesión de auth.
///
/// Evita que el usuario vea un flash del login antes de ser redirigido
/// al dashboard cuando ya tiene sesión guardada en localStorage.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco, size: 64, color: AppColors.primary),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
