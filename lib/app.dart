import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_theme.dart';
import 'presentation/router/app_router.dart';

/// Raíz de la aplicación.
///
/// [ProviderScope] envuelve todo el árbol para que los providers de Riverpod
/// estén disponibles en cualquier widget descendiente.
///
/// [MaterialApp.router] delega el enrutamiento a [routerProvider],
/// que incluye el guard de autenticación y las rutas `/login` y `/`.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Panel de Monitoreo',
      // Requisito 6.1: tema oscuro como modo por defecto.
      // Requisito 6.2: ThemeData centralizado en core/config/app_theme.dart.
      theme: appTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      // Delegates para localización (necesario para showDateRangePicker en es-MX)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'MX'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'MX'),
    );
  }
}
