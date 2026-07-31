---
inclusion: fileMatch
fileMatchPattern: 'lib/presentation/**/*.dart'
---

# Convenciones de Riverpod (sin code generation)

## Tipos de provider a usar
- `Provider`: para inyectar dependencias sin estado propio (repositorios, datasources, servicios). Ej: `sensorRepositoryProvider`.
- `NotifierProvider` / `AsyncNotifierProvider`: para estado de UI con lógica (ej. el controlador del login).
- `StreamProvider` / `StreamProvider.family`: para datos que llegan como stream desde el repositorio (ej. lectura en tiempo real de un dispositivo).
- `FutureProvider.family`: para consultas puntuales parametrizadas (ej. histórico por rango de fechas).
- Evitar `StateProvider` salvo para estado trivial de UI (ej. el rango de fecha seleccionado en un selector).

## Manejo de carga/error
Usar siempre `AsyncValue<T>` para datos async (no banderas manuales de `isLoading`/`hasError`). En la UI, usar `.when(data:, error:, loading:)`.

## Nombres
- `xxxRepositoryProvider`, `xxxDataSourceProvider`: en `infrastructure`.
- `xxxControllerProvider`: lógica de una pantalla/feature, en `presentation/providers/<feature>/`.
- `xxxProvider` a secas: datos derivados o de solo lectura (ej. `latestReadingProvider`).

## Scope y disposing
- Usar `.autoDispose` por defecto en providers que dependen de una pantalla específica (ej. detalle de un dispositivo), para no acumular streams abiertos sin usar.
- Providers compartidos por toda la app (auth, tema) sin `.autoDispose`.

## AsyncNotifier + ChangeNotifier (patrón auth)

Cuando un `AsyncNotifier` también implementa `ChangeNotifier` (para que GoRouter lo use como `refreshListenable`):

- Override del setter `state` para llamar `notifyListeners()` en cada cambio explícito (login, logout).
- Exponer un método público `notifyAuthChanged()` que llame `notifyListeners()`, para que el router pueda invocarlo desde un `ref.listen`. Esto es necesario porque `AsyncNotifier.build()` resuelve sin pasar por el setter override.
- Nunca llamar `notifyListeners()` directamente desde fuera del controller (es protegido); usar el método público.

```dart
class AuthController extends AsyncNotifier<AppUser?> with ChangeNotifier {
  @override
  set state(AsyncValue<AppUser?> newState) {
    super.state = newState;
    notifyListeners();
  }

  void notifyAuthChanged() {
    notifyListeners();
  }
}
```

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
