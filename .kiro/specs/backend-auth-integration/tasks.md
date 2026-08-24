# Implementation Plan: Backend Auth Integration

## Overview

Integrate the Flutter Web auth flow with the FastAPI backend by updating domain failures, data models, datasource contracts/implementations, adding a Dio token interceptor for automatic refresh, and updating the UI to handle specific error types. Changes follow Clean Architecture: domain first, then infrastructure, then presentation wiring and UI.

## Tasks

- [x] 1. Domain layer updates
  - [x] 1.1 Update AppFailure sealed class with new subtypes
    - Add `InvalidCredentialsFailure`, `EmailAlreadyExistsFailure`, `ValidationFailure`, `SessionExpiredFailure` to `lib/domain/failures/app_failure.dart`
    - Keep existing `NetworkFailure` if present, otherwise add it
    - Use `sealed class AppFailure implements Exception` with a `message` field
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [x] 1.2 Update AuthRepository contract — remove `name` from register
    - Modify `lib/domain/repositories/auth_repository.dart` so `register` signature is `Future<AppUser> register(String email, String password)`
    - _Requirements: 4.1, 4.2, 4.3_

- [x] 2. Core utilities and new models
  - [x] 2.1 Create JWT decode utility
    - Create `lib/core/utils/jwt_utils.dart` with `Map<String, dynamic> decodeJwtPayload(String token)` function
    - Splits JWT into parts, base64Url-decodes the payload, returns decoded JSON map
    - Throws `FormatException` if token doesn't have 3 parts
    - _Requirements: 5.1, 5.2_

  - [x] 2.2 Create TokenPairDto
    - Create `lib/infrastructure/models/token_pair_dto.dart`
    - Fields: `userId`, `email`, `accessToken`, `refreshToken`
    - Include `toEntity()` method returning `AppUser(id: userId, email: email, token: accessToken)`
    - _Requirements: 1.1, 4.3, 5.2_

- [x] 3. Local datasource updates
  - [x] 3.1 Update LocalAuthDataSource contract
    - In `lib/infrastructure/datasources/auth/local_auth_datasource.dart`, add:
      - `Future<String?> readRefreshToken()`
      - `Future<void> updateAccessToken(String token)`
      - Add `required String refreshToken` parameter to `saveSession`
    - _Requirements: 1.1, 1.2, 1.3, 3.3_

  - [x] 3.2 Update LocalAuthDataSourceSharedPrefs implementation
    - In `lib/infrastructure/datasources/auth/local_auth_datasource_shared_prefs.dart`:
      - Add `_keyRefreshToken = 'auth_refresh_token'` constant
      - Implement `readRefreshToken()` reading from SharedPreferences
      - Implement `updateAccessToken()` writing only the access token key
      - Update `saveSession()` to persist the refresh token
      - Update `clearSession()` to remove the refresh token key
    - _Requirements: 1.1, 1.2, 1.3, 7.1_

- [x] 4. Remote datasource updates
  - [x] 4.1 Update AuthRemoteDataSource contract
    - In `lib/infrastructure/datasources/auth/auth_remote_datasource.dart`:
      - Change `signIn` return type to `Future<TokenPairDto>`
      - Change `register` to `Future<TokenPairDto> register(String email, String password)` (no name)
      - Add `Future<String> refreshToken(String refreshToken)` method
      - Update imports to include `token_pair_dto.dart`
    - _Requirements: 2.1, 4.1, 4.2_

  - [x] 4.2 Rewrite AuthRemoteDataSourceBackend
    - Rewrite `lib/infrastructure/datasources/auth/auth_remote_datasource_backend.dart`:
      - Inject `Dio` (baseDio) via constructor
      - `signIn`: POST `/auth/login`, decode JWT `sub` claim for userId via `decodeJwtPayload`, return `TokenPairDto`, throw `InvalidCredentialsFailure` on 401
      - `register`: POST `/auth/register` (email+password only), extract `id` from response, then auto-login via POST `/auth/login`, return `TokenPairDto`, throw `EmailAlreadyExistsFailure` on 409, `ValidationFailure` on 422
      - `refreshToken`: POST `/auth/refresh` with refresh_token body, return new access_token string, throw `SessionExpiredFailure` on 401
      - `signOut`: no-op (backend has no logout endpoint)
      - Wrap all `DioException` catches with `NetworkFailure` fallback
    - _Requirements: 1.1, 2.1, 2.2, 4.1, 4.2, 4.3, 5.1, 6.1, 6.2, 6.3, 6.4_

  - [x] 4.3 Update AuthRemoteDataSourceFake to match new contract
    - Update `lib/infrastructure/datasources/auth/auth_remote_datasource_fake.dart`:
      - Return `TokenPairDto` from `signIn` and `register`
      - Add `refreshToken` method (return a dummy token)
      - Remove `name` parameter from `register`
    - _Requirements: 4.1_

- [x] 5. Checkpoint — Domain and datasource contracts compile
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Network layer — Dio providers and Token Interceptor
  - [x] 6.1 Create TokenInterceptor
    - Create `lib/infrastructure/network/token_interceptor.dart`
    - Depends on `LocalAuthDataSource` (read token, update token) and `AuthRemoteDataSource` (refresh)
    - `onRequest`: attach `Authorization: Bearer <access_token>` header
    - `onError`: if 401 and not an auth endpoint, refresh token and retry once
    - Use `Completer`-based queue to avoid concurrent refresh calls
    - Accept `onSessionExpired` callback for triggering logout on refresh failure
    - Skip refresh for `/auth/login`, `/auth/refresh`, `/auth/register` paths
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 6.2 Create Dio providers
    - Create `lib/infrastructure/network/dio_provider.dart`
    - `baseDioProvider`: plain Dio with `BaseOptions(baseUrl: ...)`, no interceptor
    - `authenticatedDioProvider`: Dio with `TokenInterceptor` added, uses `authLocalDataSourceProvider` and `authDataSourceProvider`
    - Wire `onSessionExpired` to call `authControllerProvider.notifier.logout()`
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 7. Repository and provider wiring
  - [x] 7.1 Update AuthRepositoryImpl
    - In `lib/infrastructure/repositories/auth_repository_impl.dart`:
      - `login`: call `_dataSource.signIn(...)`, get `TokenPairDto`, call `_localStorage.saveSession(...)` with all four fields, emit auth state
      - `register`: call `_dataSource.register(email, password)` (no name), persist full session
      - `logout`: call `_localStorage.clearSession()`, emit null state
      - `restoreSession`: read all fields from local storage, rebuild `AppUser`
    - _Requirements: 1.1, 1.2, 2.3, 4.3, 5.3, 7.1, 7.2_

  - [x] 7.2 Remove AppUserDto and update imports
    - Delete `lib/infrastructure/models/app_user_dto.dart`
    - Find and update any files importing `app_user_dto.dart` to use `token_pair_dto.dart` instead
    - _Requirements: 5.2_

  - [x] 7.3 Update auth_datasource_provider — inject baseDio
    - In `lib/presentation/providers/auth/auth_datasource_provider.dart`:
      - Import `dio_provider.dart`
      - Change `authDataSourceProvider` to inject `ref.watch(baseDioProvider)` into `AuthRemoteDataSourceBackend`
    - _Requirements: 3.1_

  - [x] 7.4 Update AuthController and auth_providers — remove `name` from register
    - In `lib/presentation/providers/auth/auth_providers.dart` (or wherever `AuthController` lives):
      - Update `register` method signature to `register(String email, String password)`
      - Remove any `name` parameter usage
    - _Requirements: 4.3_

- [x] 8. Checkpoint — Infrastructure compiles and wiring is correct
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Presentation layer — UI updates
  - [x] 9.1 Update LoginPage — show specific error messages
    - In `lib/presentation/pages/auth/login_page.dart`:
      - Pattern match on `AppFailure` subtypes (`InvalidCredentialsFailure`, `NetworkFailure`, etc.)
      - Display the failure's `message` to the user (SnackBar or inline text)
    - _Requirements: 6.1, 6.4_

  - [x] 9.2 Update RegisterPage — drop name field, show specific errors
    - In `lib/presentation/pages/auth/register_page.dart`:
      - Remove the name `TextFormField` and its controller/validation
      - Call `register(email, password)` without name
      - Pattern match on `AppFailure` subtypes (`EmailAlreadyExistsFailure`, `ValidationFailure`, `NetworkFailure`)
      - Display the failure's `message` to the user
    - _Requirements: 4.3, 6.2, 6.3, 6.4_

- [x] 10. Final checkpoint — Full build passes
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- No property-based tests included (design has no Correctness Properties section; this is infrastructure/integration work).
- Unit tests are recommended for `jwt_utils.dart`, `TokenInterceptor`, and `AuthRemoteDataSourceBackend` but are left to the developer's discretion since the project is a personal learning project.
- Each task references specific requirements for traceability.
- Checkpoints ensure incremental validation after each architectural layer is complete.
- Two Dio instances (`baseDio` and `authenticatedDio`) prevent circular dependency during token refresh.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "2.1", "2.2"] },
    { "id": 1, "tasks": ["3.1", "4.1"] },
    { "id": 2, "tasks": ["3.2", "4.2", "4.3"] },
    { "id": 3, "tasks": ["6.1"] },
    { "id": 4, "tasks": ["6.2"] },
    { "id": 5, "tasks": ["7.1", "7.2", "7.3", "7.4"] },
    { "id": 6, "tasks": ["9.1", "9.2"] }
  ]
}
```
