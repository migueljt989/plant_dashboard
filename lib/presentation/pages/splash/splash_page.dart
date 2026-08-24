import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_theme.dart';
import '../../providers/auth/auth_providers.dart';
import '../../router/app_routes.dart';

/// Pantalla de carga mostrada mientras se restaura la sesión de auth.
///
/// Si [restoreSessionProvider] resuelve sin usuario, navega a login.
/// Si resuelve con usuario, el router redirige a dashboard automáticamente
/// (porque [authSessionProvider] se actualiza desde el router provider).
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restoreAsync = ref.watch(restoreSessionProvider);

    // Si ya resolvió sin usuario, navegar a login.
    if (restoreAsync.hasValue && restoreAsync.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.login);
      });
    }

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
