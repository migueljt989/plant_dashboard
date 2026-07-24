---
inclusion: fileMatch
fileMatchPattern: 'lib/presentation/router/**/*.dart'
---

# Convenciones de go_router

## Rutas como constantes
Definir todas las rutas en `app_routes.dart` como constantes de string, nunca strings sueltos repetidos en el código:

```dart
class AppRoutes {
  static const login = '/login';
  static const dashboard = '/';
  static const deviceDetail = '/dispositivo/:deviceId';
}
```

## Guard de autenticación
El guard de login va en `redirect` de `GoRouter`, escuchando el estado de auth (ej. envolviendo el provider de auth con un `Listenable` que GoRouter pueda usar como `refreshListenable`). No poner lógica de auth dentro de cada página.

Idea de referencia (ajustar según la implementación final de auth):
```dart
GoRouter(
  redirect: (context, state) {
    final isLoggedIn = /* leer estado de auth */;
    final goingToLogin = state.matchedLocation == AppRoutes.login;
    if (!isLoggedIn && !goingToLogin) return AppRoutes.login;
    if (isLoggedIn && goingToLogin) return AppRoutes.dashboard;
    return null;
  },
  routes: [...],
)
```

## Parámetros de ruta
Usar `state.pathParameters['deviceId']` para parámetros de ruta, tipados explícitamente al entrar a la página. No pasar objetos completos por `extra` salvo que sea estrictamente necesario (rompe deep-linking).

## Estructura de rutas anidadas
Si el dashboard crece (ej. tabs internos para dispositivos, histórico, ajustes), usar `ShellRoute` para mantener una barra de navegación persistente en vez de duplicar el `Scaffold` en cada página.
