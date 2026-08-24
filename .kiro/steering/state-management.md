---
inclusion: fileMatch
fileMatchPattern: 'lib/presentation/**/*.dart'
---

# Convenciones de Riverpod (sin code generation)

## Tipos de provider a usar
- `Provider`: para inyectar dependencias sin estado propio (repositorios, datasources, servicios). Ej: `sensorRepositoryProvider`.
- `NotifierProvider` / `AsyncNotifierProvider`: para estado de UI con lógica (ej. controladores de formulario).
- `AsyncNotifierProvider.autoDispose`: para estado de formulario que debe limpiarse al salir de la página.
- `StreamProvider` / `StreamProvider.family`: para datos que llegan como stream desde el repositorio (ej. lectura en tiempo real de un dispositivo).
- `FutureProvider` / `FutureProvider.family`: para consultas puntuales (ej. histórico por rango de fechas, restauración de sesión).
- Evitar `StateProvider` salvo para estado trivial de UI (ej. el rango de fecha seleccionado en un selector).

## Manejo de carga/error
Usar siempre `AsyncValue<T>` para datos async (no banderas manuales de `isLoading`/`hasError`). En la UI, usar `.when(data:, error:, loading:)`.

## Nombres
- `xxxRepositoryProvider`, `xxxDataSourceProvider`: en `infrastructure`.
- `xxxControllerProvider`: lógica de una pantalla/feature, en `presentation/providers/<feature>/`.
- `xxxProvider` a secas: datos derivados o de solo lectura (ej. `latestReadingProvider`).

## Scope y disposing
- Usar `.autoDispose` por defecto en providers que dependen de una pantalla específica (ej. detalle de un dispositivo, formulario de login), para no acumular estado stale.
- Providers compartidos por toda la app (sesión, tema) sin `.autoDispose`.

## Patrón de autenticación: separación de estado de sesión vs. estado de formulario

**Principio clave:** El estado de sesión (¿hay usuario autenticado?) y el estado de formulario (loading/error de login/register) son responsabilidades distintas y viven en providers separados.

### Estado de sesión (`authSessionProvider`)

Un `NotifierProvider<AuthSessionNotifier, AppUser?>` global que solo tiene dos estados: `null` (no autenticado) o `AppUser` (autenticado). Nunca loading, nunca error.

Implementa `ChangeNotifier` para que GoRouter lo use como `refreshListenable`:

```dart
final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AppUser?>(() => AuthSessionNotifier());

class AuthSessionNotifier extends Notifier<AppUser?> with ChangeNotifier {
  @override
  AppUser? build() => null;

  void setUser(AppUser? user) {
    state = user;
    notifyListeners();
  }
}
```

GoRouter escucha SOLO este provider. No se entera de errores de formulario.

### Restauración de sesión (`restoreSessionProvider`)

Un `FutureProvider` que lee la sesión persistida al inicio. El splash lo consume y vuelca el resultado a `authSessionProvider`:

```dart
final restoreSessionProvider = FutureProvider<AppUser?>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  if (repo is AuthRepositoryImpl) {
    return repo.restoreSession();
  }
  return null;
});
```

### Controllers de formulario (`loginControllerProvider`, `registerControllerProvider`)

`AsyncNotifierProvider.autoDispose<T, void>` — manejan loading/error del submit. Al ser autoDispose, mueren cuando la página se desmonta. Si el usuario navega de login a register, el error del login desaparece automáticamente sin lógica manual.

```dart
final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, void>(
  () => LoginController(),
);

class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).login(email, password);
      ref.read(authSessionProvider.notifier).setUser(user);
    });
    return !state.hasError;
  }
}
```

El controller devuelve `bool` para que la UI sepa si debe navegar:
```dart
final success = await ref.read(loginControllerProvider.notifier).login(email, password);
if (mounted && success) context.go(AppRoutes.dashboard);
```

### Logout (`logoutProvider`)

Función reutilizable desde dashboard, interceptor, etc.:

```dart
final logoutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(authSessionProvider.notifier).setUser(null);
  };
});
```

### Por qué NO usar un solo AsyncNotifier para todo

Mezclar sesión + formulario en un solo provider causa:
- GoRouter se confunde: recibe notificaciones por errores de formulario y re-evalúa redirect innecesariamente.
- El router puede redirigir al splash durante el loading transitorio de un submit.
- Los errores "se pegan" entre páginas porque el provider es global.

La separación resuelve esto por diseño, sin workarounds.

## Cómo un widget consume datos
```dart
class DashboardPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(latestReadingProvider('device-1'));
    return reading.when(
      data: (r) => SensorCard(reading: r),
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => ErrorBanner(message: e.toString()),
    );
  }
}
```

## Lo que Kiro NO debe hacer
- No mezclar `setState` con Riverpod en la misma pantalla.
- No leer un repositorio directamente dentro de un widget; siempre pasar por un provider/controller.
- No usar un solo provider global para estado de sesión + estado de formulario.
- No hacer que GoRouter escuche errores de formulario (solo debe escuchar transiciones de sesión).
