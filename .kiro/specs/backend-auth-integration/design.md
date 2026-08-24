# Technical Design: Backend Auth Integration

## Overview

This design describes how to evolve the current auth infrastructure to fully integrate with the FastAPI backend. The main additions are: persisting both tokens, a shared Dio instance with a token interceptor, proper error mapping, and updated data models carrying the real backend UUID.

The design preserves the existing Clean Architecture layers and Riverpod wiring. Changes are surgical — most files are updated, not replaced.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                       PRESENTATION                               │
│                                                                   │
│  AuthController (AsyncNotifier + ChangeNotifier)                 │
│       ↓ ref.read                                                 │
│  authRepositoryProvider → AuthRepository (abstract)              │
└───────────────────────────────┬──────────────────────────────────┘
                                │
┌───────────────────────────────▼──────────────────────────────────┐
│                       INFRASTRUCTURE                              │
│                                                                   │
│  AuthRepositoryImpl                                              │
│    ├── AuthRemoteDataSource (contract)                           │
│    │     └── AuthRemoteDataSourceBackend (Dio calls)             │
│    └── LocalAuthDataSource (contract)                            │
│          └── LocalAuthDataSourceSharedPrefs                      │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │  Shared Dio instance (dioProvider)                       │     │
│  │    └── TokenInterceptor                                  │     │
│  │          ├── reads token from LocalAuthDataSource         │     │
│  │          ├── refreshes via AuthRemoteDataSource.refresh() │     │
│  │          └── on refresh fail → triggers logout callback   │     │
│  └─────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────┘
```

## Component Design

### 1. Updated Domain Layer

#### AppUser Entity

```dart
// lib/domain/entities/app_user.dart
class AppUser {
  final String id;       // UUID from backend
  final String email;
  final String token;    // access_token (kept for compatibility with router/guard)

  const AppUser({required this.id, required this.email, required this.token});
}
```

No change to the entity shape — `token` remains the access_token. The refresh_token is an infrastructure concern and does NOT leak into domain.

#### Auth Failures (updated)

```dart
// lib/domain/failures/app_failure.dart
sealed class AppFailure implements Exception {
  final String message;
  const AppFailure(this.message);
}

class InvalidCredentialsFailure extends AppFailure {
  const InvalidCredentialsFailure() : super('Credenciales inválidas');
}

class EmailAlreadyExistsFailure extends AppFailure {
  const EmailAlreadyExistsFailure() : super('El correo ya está registrado');
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

class SessionExpiredFailure extends AppFailure {
  const SessionExpiredFailure() : super('Sesión expirada, inicia sesión de nuevo');
}
```

#### AuthRepository Contract (updated)

```dart
// lib/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<AppUser> login(String email, String password);
  Future<AppUser> register(String email, String password);  // name removed (backend doesn't use it)
  Future<void> logout();
  AppUser? get currentUser;
  Stream<AppUser?> get authStateChanges;
}
```

Note: `register` drops the `name` parameter since the backend's `/auth/register` only accepts `email` + `password`.

---

### 2. Updated Infrastructure Layer

#### LocalAuthDataSource Contract (add refresh token)

```dart
// lib/infrastructure/datasources/auth/local_auth_datasource.dart
abstract class LocalAuthDataSource {
  Future<String?> readUserId();
  Future<String?> readEmail();
  Future<String?> readToken();         // access_token
  Future<String?> readRefreshToken();  // NEW

  Future<void> saveSession({
    required String userId,
    required String email,
    required String token,
    required String refreshToken,      // NEW
  });

  Future<void> updateAccessToken(String token);  // NEW — for interceptor refresh

  Future<void> clearSession();
}
```

#### LocalAuthDataSourceSharedPrefs (updated)

Adds `_keyRefreshToken = 'auth_refresh_token'`, implements `readRefreshToken()` and `updateAccessToken()`.

#### AuthRemoteDataSource Contract (add refresh)

```dart
// lib/infrastructure/datasources/auth/auth_remote_datasource.dart
import '../../models/app_user_dto.dart';
import '../../models/token_pair_dto.dart';

abstract class AuthRemoteDataSource {
  /// Login → returns TokenPairDto (access + refresh + user info)
  Future<TokenPairDto> signIn(String email, String password);

  /// Register → returns user id + email, then auto-logins
  Future<TokenPairDto> register(String email, String password);

  /// Refresh → returns new access_token only
  Future<String> refreshToken(String refreshToken);

  Future<void> signOut();
}
```

#### New DTO: TokenPairDto

```dart
// lib/infrastructure/models/token_pair_dto.dart
import '../../domain/entities/app_user.dart';

/// Represents the combined result of login (or register+login):
/// the user identity + both tokens.
class TokenPairDto {
  final String userId;
  final String email;
  final String accessToken;
  final String refreshToken;

  const TokenPairDto({
    required this.userId,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
  });

  AppUser toEntity() => AppUser(id: userId, email: email, token: accessToken);
}
```

#### AuthRemoteDataSourceBackend (updated)

```dart
// lib/infrastructure/datasources/auth/auth_remote_datasource_backend.dart
class AuthRemoteDataSourceBackend implements AuthRemoteDataSource {
  final Dio _dio;  // injected — the shared Dio WITHOUT the token interceptor (to avoid circular refresh)

  AuthRemoteDataSourceBackend(this._dio);

  @override
  Future<TokenPairDto> signIn(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return TokenPairDto(
        userId: '', // login response doesn't include user id — see note below
        email: email,
        accessToken: response.data['access_token'] as String,
        refreshToken: response.data['refresh_token'] as String,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const InvalidCredentialsFailure();
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<TokenPairDto> register(String email, String password) async {
    try {
      final regResponse = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
      });
      final userId = regResponse.data['id'] as String;

      // Auto-login to get tokens
      final loginResponse = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return TokenPairDto(
        userId: userId,
        email: email,
        accessToken: loginResponse.data['access_token'] as String,
        refreshToken: loginResponse.data['refresh_token'] as String,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw const EmailAlreadyExistsFailure();
      }
      if (e.response?.statusCode == 422) {
        final detail = e.response?.data?['detail'];
        final msg = detail is List ? detail.first['msg'] as String : '$detail';
        throw ValidationFailure(msg);
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      return response.data['access_token'] as String;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const SessionExpiredFailure();
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<void> signOut() async {
    // Backend has no explicit logout endpoint — just clear local state
  }
}
```

**Note on user ID during login-only flow:** The `/auth/login` response does not return the user ID. Two options:
- Option A: Store the user ID from the registration step; on login-only, the userId will be empty until we have a `/auth/me` endpoint. We persist whatever we have.
- Option B: Decode the JWT access_token client-side to extract the `sub` claim (most FastAPI JWT implementations include it).

**Decision: Option B** — decode the JWT `sub` claim. This avoids needing a separate `/auth/me` endpoint and gives us the user ID on every login. We'll add a simple JWT decode utility (base64, no verification needed client-side since the backend already validated it).

#### JWT Decode Utility

```dart
// lib/core/utils/jwt_utils.dart
import 'dart:convert';

/// Extracts the payload from a JWT without verifying the signature.
/// Used client-side only to read the `sub` (user ID) claim.
Map<String, dynamic> decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) throw const FormatException('Invalid JWT');
  final payload = parts[1];
  final normalized = base64Url.normalize(payload);
  final decoded = utf8.decode(base64Url.decode(normalized));
  return json.decode(decoded) as Map<String, dynamic>;
}
```

---

### 3. Token Interceptor

```dart
// lib/infrastructure/network/token_interceptor.dart
import 'dart:async';
import 'package:dio/dio.dart';
import '../datasources/auth/local_auth_datasource.dart';
import '../datasources/auth/auth_remote_datasource.dart';

class TokenInterceptor extends Interceptor {
  final LocalAuthDataSource _localStorage;
  final AuthRemoteDataSource _authDataSource;
  final void Function() _onSessionExpired;

  Completer<String>? _refreshCompleter;

  TokenInterceptor({
    required LocalAuthDataSource localStorage,
    required AuthRemoteDataSource authDataSource,
    required void Function() onSessionExpired,
  })  : _localStorage = localStorage,
        _authDataSource = authDataSource,
        _onSessionExpired = onSessionExpired;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _localStorage.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Skip refresh for auth endpoints themselves
    final path = err.requestOptions.path;
    if (path == '/auth/login' || path == '/auth/refresh' || path == '/auth/register') {
      return handler.next(err);
    }

    try {
      final newToken = await _getRefreshedToken();
      // Retry original request with new token
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newToken';
      final response = await Dio().fetch(opts);
      return handler.resolve(response);
    } catch (_) {
      _onSessionExpired();
      return handler.next(err);
    }
  }

  /// Ensures only one refresh happens at a time. Concurrent 401s wait for the same result.
  Future<String> _getRefreshedToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String>();
    try {
      final refreshToken = await _localStorage.readRefreshToken();
      if (refreshToken == null) throw const SessionExpiredFailure();

      final newAccessToken = await _authDataSource.refreshToken(refreshToken);
      await _localStorage.updateAccessToken(newAccessToken);
      _refreshCompleter!.complete(newAccessToken);
      return newAccessToken;
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }
}
```

---

### 4. Shared Dio Provider

```dart
// lib/infrastructure/network/dio_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/auth/local_auth_datasource.dart';
import '../datasources/auth/auth_remote_datasource.dart';
import 'token_interceptor.dart';

/// Base Dio instance WITHOUT interceptor — used by AuthRemoteDataSource
/// to avoid circular dependency during token refresh.
final baseDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'));
});

/// Dio instance WITH token interceptor — used by all other datasources
/// (sensors, devices, readings, alerts).
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'));
  final localStorage = ref.watch(authLocalDataSourceProvider);
  final authDataSource = ref.watch(authDataSourceProvider);

  dio.interceptors.add(TokenInterceptor(
    localStorage: localStorage,
    authDataSource: authDataSource,
    onSessionExpired: () {
      // Trigger logout through the auth controller
      ref.read(authControllerProvider.notifier).logout();
    },
  ));

  return dio;
});
```

**Key design decision:** Two Dio instances to avoid circular refresh. `baseDio` is plain (no interceptor), used only by the auth datasource. `authenticatedDio` has the interceptor and is used by all other feature datasources (sensors, readings, etc.).

---

### 5. Updated AuthRepositoryImpl

```dart
// lib/infrastructure/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final LocalAuthDataSource _localStorage;
  AppUser? _currentUser;
  final _authStateController = StreamController<AppUser?>.broadcast();

  AuthRepositoryImpl(this._dataSource, this._localStorage);

  Future<AppUser?> restoreSession() async {
    final userId = await _localStorage.readUserId();
    final email = await _localStorage.readEmail();
    final token = await _localStorage.readToken();
    if (userId != null && email != null && token != null) {
      _currentUser = AppUser(id: userId, email: email, token: token);
      _authStateController.add(_currentUser);
      return _currentUser;
    }
    return null;
  }

  @override
  Future<AppUser> login(String email, String password) async {
    final tokenPair = await _dataSource.signIn(email, password);
    _currentUser = tokenPair.toEntity();
    await _localStorage.saveSession(
      userId: _currentUser!.id,
      email: _currentUser!.email,
      token: tokenPair.accessToken,
      refreshToken: tokenPair.refreshToken,
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<AppUser> register(String email, String password) async {
    final tokenPair = await _dataSource.register(email, password);
    _currentUser = tokenPair.toEntity();
    await _localStorage.saveSession(
      userId: _currentUser!.id,
      email: _currentUser!.email,
      token: tokenPair.accessToken,
      refreshToken: tokenPair.refreshToken,
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await _dataSource.signOut();
    await _localStorage.clearSession();
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;
}
```

---

### 6. Updated Provider Wiring

```dart
// lib/presentation/providers/auth/auth_datasource_provider.dart
final authDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(baseDioProvider);
  return AuthRemoteDataSourceBackend(dio);
});
```

The `authLocalDataSourceProvider`, `authRepositoryProvider`, and `authControllerProvider` remain mostly the same. The controller's `register` method drops the `name` parameter.

---

### 7. Updated AuthController

Minor changes:
- `register(String email, String password)` — no `name` parameter.
- Error handling in the UI uses pattern matching on `AppFailure` subtypes to show specific messages.

---

## File Changes Summary

| File | Action | Requirement |
|------|--------|-------------|
| `lib/domain/failures/app_failure.dart` | Update — add failure subtypes | R6 |
| `lib/domain/repositories/auth_repository.dart` | Update — remove `name` from register | R4 |
| `lib/domain/entities/app_user.dart` | No change | R5 |
| `lib/core/utils/jwt_utils.dart` | **New** — JWT payload decoder | R5 |
| `lib/infrastructure/models/token_pair_dto.dart` | **New** — login/register response DTO | R1, R4 |
| `lib/infrastructure/datasources/auth/local_auth_datasource.dart` | Update — add refreshToken methods | R1, R7 |
| `lib/infrastructure/datasources/auth/local_auth_datasource_shared_prefs.dart` | Update — implement new methods | R1, R7 |
| `lib/infrastructure/datasources/auth/auth_remote_datasource.dart` | Update — new signature + refreshToken | R2, R4 |
| `lib/infrastructure/datasources/auth/auth_remote_datasource_backend.dart` | Rewrite — proper error handling + refresh | R1-R6 |
| `lib/infrastructure/datasources/auth/auth_remote_datasource_fake.dart` | Update — match new contract | — |
| `lib/infrastructure/network/token_interceptor.dart` | **New** | R3 |
| `lib/infrastructure/network/dio_provider.dart` | **New** — baseDio + authenticatedDio | R3 |
| `lib/infrastructure/repositories/auth_repository_impl.dart` | Update — use TokenPairDto, refreshToken | R1-R5, R7 |
| `lib/infrastructure/models/app_user_dto.dart` | Remove (replaced by TokenPairDto) | R5 |
| `lib/presentation/providers/auth/auth_datasource_provider.dart` | Update — inject baseDio | R3 |
| `lib/presentation/providers/auth/auth_providers.dart` | Update — remove `name` from register | R4 |
| `lib/presentation/pages/auth/login_page.dart` | Update — show specific error messages | R6 |
| `lib/presentation/pages/auth/register_page.dart` | Update — drop name field, show errors | R4, R6 |

## Key Design Decisions

1. **Two Dio instances** (base vs authenticated) to prevent circular dependency during token refresh.
2. **JWT decode client-side** to extract user ID on login (avoids needing a `/auth/me` endpoint).
3. **Refresh token stays in infrastructure** — domain only sees the access_token via `AppUser.token`. The refresh_token is an implementation detail of the interceptor + local storage.
4. **Completer-based queue** in the interceptor ensures only one refresh call happens at a time, and concurrent 401-failing requests all resolve with the same new token.
5. **AppUserDto removed** in favor of `TokenPairDto` which better represents what the backend actually returns (tokens + user info combined from register+login).
6. **`name` parameter removed from register** — the backend doesn't accept it. Keeping it would be misleading.
