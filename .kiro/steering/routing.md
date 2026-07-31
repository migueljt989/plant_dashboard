---
inclusion: fileMatch
fileMatchPattern: 'lib/presentation/router/**/*.dart'
---

# Convenciones de go_router

## Rutas como constantes
Definir todas las rutas en `app_routes.dart` como constantes de string, nunca strings sueltos repetidos en el código:

```dart
class AppRoutes {
  static const splash = '/';        // ruta raíz = splash de carga
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const deviceDetail = '/dispositivo/:deviceId';
}
```

## Guard de autenticación con splash

El guard vive en `redirect` de `GoRouter`. Usa una pantalla de splash (`/`) como sala de espera mientras se restaura la sesión desde localStorage, evitando flashes del login o del dashboard.

### Lógica del redirect (3 fases)

1. **Estado loading** (restaurando sesión): redirigir a `/` (splash). No tomar decisiones de auth todavía.
2. **Autenticado**: si está en `/login` o `/` (splash) → mandar a `/dashboard`. Si ya está en una ruta protegida → no hacer nada.
3. **No autenticado**: si no está en `/login` → mandar a `/login`. Si ya está en `/login` → no hacer nada.

Referencia actual:
```dart
GoRouter(
  refreshListenable: authNotifier,
  redirect: (context, state) {
    final authState = ref.read(authControllerProvider);
    final location = state.matchedLocation;
    final goingToLogin = location == AppRoutes.login;
    final goingToSplash = location == AppRoutes.splash;

    if (authState.isLoading) {
      return goingToSplash ? null : AppRoutes.splash;
    }

    final isLoggedIn = authState.value != null;

    if (isLoggedIn) {
      if (goingToLogin || goingToSplash) return AppRoutes.dashboard;
      return null;
    }

    if (!goingToLogin) return AppRoutes.login;
    return null;
  },
  routes: [...],
)
```

### refreshListenable + ref.listen

`AuthController` extiende `ChangeNotifier` y se usa como `refreshListenable`. Pero `AsyncNotifier.build()` no pasa por el setter override al resolver, así que se necesita un `ref.listen` en el `routerProvider` que llame `authNotifier.notifyAuthChanged()` para forzar la re-evaluación del redirect cuando `restoreSession` termina.

```dart
ref.listen(authControllerProvider, (prev, next) {
  authNotifier.notifyAuthChanged();
});
```

### Navegación explícita tras login

Después de un login exitoso en la UI, llamar `context.go(AppRoutes.dashboard)` explícitamente para asegurar que la URL del browser se actualice correctamente (no depender solo del redirect vía refreshListenable para este caso).

## Parámetros de ruta
Usar `state.pathParameters['deviceId']` para parámetros de ruta, tipados explícitamente al entrar a la página. No pasar objetos completos por `extra` salvo que sea estrictamente necesario (rompe deep-linking).

## Estructura de rutas anidadas
Si el dashboard crece (ej. tabs internos para dispositivos, histórico, ajustes), usar `ShellRoute` para mantener una barra de navegación persistente en vez de duplicar el `Scaffold` en cada página.
