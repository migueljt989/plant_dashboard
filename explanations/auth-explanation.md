## Cómo funciona el flujo de auth + routing

### Las piezas

1. **`AuthController`** — un `AsyncNotifier<AppUser?>` que también es `ChangeNotifier` (para que GoRouter lo escuche).
2. **`GoRouter`** con `refreshListenable` apuntando al controller, y un `redirect` que decide a dónde mandar al usuario.
3. **3 rutas**: `/` (splash), `/login`, `/dashboard`.

---

### El estado de auth tiene 3 posibilidades

| Estado | Significado |
|--------|-------------|
| `AsyncLoading` | Aún no sabemos si hay sesión (se está leyendo localStorage) |
| `AsyncData(AppUser)` | Hay sesión activa |
| `AsyncData(null)` | No hay sesión |

---

### La lógica del redirect (en pseudocódigo)

```
si estado == loading:
    → mandar al splash (spinner neutro)

si está autenticado:
    si está en /login o /splash → mandar a /dashboard
    si ya está en /dashboard → no hacer nada

si NO está autenticado:
    si no está en /login → mandar a /login
    si ya está en /login → no hacer nada
```

---

### Los flujos concretos

**App arranca por primera vez (sin sesión):**
```
/ → loading → redirect manda a /splash
     ↓
restoreSession() → null
     ↓
notifyAuthChanged() → redirect re-evalúa
     ↓
no autenticado + en splash → redirect manda a /login
```

**F5 después de login (con sesión en localStorage):**
```
/ → loading → redirect manda a /splash
     ↓
restoreSession() → AppUser
     ↓
notifyAuthChanged() → redirect re-evalúa
     ↓
autenticado + en splash → redirect manda a /dashboard
```

**Login exitoso desde el formulario:**
```
_submit() → authController.login()
     ↓
estado pasa a AsyncData(AppUser)
     ↓
context.go('/dashboard') → navega explícitamente (actualiza URL del browser)
```

**Logout:**
```
authController.logout() → estado pasa a AsyncData(null)
     ↓
notifyAuthChanged() → redirect re-evalúa
     ↓
no autenticado + en /dashboard → redirect manda a /login
```

---

### El detalle del `ref.listen`

```dart
ref.listen(authControllerProvider, (prev, next) {
  authNotifier.notifyAuthChanged();
});
```

Esto existe porque cuando `build()` (el `restoreSession`) resuelve, Riverpod asigna el resultado al estado internamente **sin pasar por el setter override**. Sin este listener, GoRouter nunca se enteraría de que la sesión se restauró y el usuario se quedaría atrapado en el splash para siempre.

El `ref.listen` detecta cualquier cambio en el `AsyncValue` y fuerza un `notifyListeners()` para que GoRouter re-evalúe el redirect.

---

### En resumen

El splash es un "sala de espera" que evita mostrar login o dashboard antes de saber el estado real. Una vez que `restoreSession` resuelve, el redirect toma la decisión correcta y manda al usuario al lugar que corresponde.