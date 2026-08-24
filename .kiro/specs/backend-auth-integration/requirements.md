# Requirements Document

## Introduction

Full integration of the Flutter Web plant IoT dashboard authentication flow with the FastAPI backend API. The current implementation partially handles login and register but does not persist refresh tokens, does not auto-refresh expired access tokens, uses a hardcoded user ID, and lacks proper error mapping. This spec covers fixing token handling, implementing automatic token refresh via a Dio interceptor, updating the data model to use the real UUID from the backend, and handling all error cases defined in the API contract.

## Glossary

- **Auth_Remote_DataSource**: Abstract contract for remote authentication operations (login, register, refresh, sign-out) located in the infrastructure layer.
- **Local_Auth_DataSource**: Abstract contract for persisting authentication session data (tokens, user ID, email) in browser localStorage.
- **Token_Interceptor**: A Dio interceptor that attaches the Bearer access token to outgoing requests and transparently refreshes it upon receiving a 401 response.
- **Access_Token**: A short-lived JWT returned by the backend on login or refresh, used as the Bearer credential for authenticated API calls.
- **Refresh_Token**: A longer-lived opaque token returned by the backend on login, used exclusively to obtain a new Access_Token without re-authenticating.
- **AppUser**: Domain entity representing an authenticated user (id, email, token).
- **AppUserDto**: Infrastructure-layer data transfer object that maps backend JSON responses to the AppUser entity.
- **Auth_Repository**: Domain-layer abstract contract that exposes login, register, logout, and session state to the presentation layer.

## Requirements

### Requirement 1: Persist Both Tokens on Login

**User Story:** As a user, I want both the access token and refresh token to be saved after login, so that the app can silently refresh my session without requiring me to log in again.

#### Acceptance Criteria

1. WHEN the backend returns a successful login response containing access_token and refresh_token, THE Local_Auth_DataSource SHALL persist both tokens alongside the user ID and email.
2. WHEN a session is restored from local storage, THE Local_Auth_DataSource SHALL provide both the access_token and refresh_token to the caller.
3. THE Local_Auth_DataSource SHALL expose a dedicated read method for the refresh_token separate from the access_token.

### Requirement 2: Token Refresh

**User Story:** As a user, I want the app to automatically obtain a new access token using my refresh token, so that I remain authenticated without manual intervention when the access token expires.

#### Acceptance Criteria

1. WHEN the stored refresh_token is available, THE Auth_Remote_DataSource SHALL send a POST request to /auth/refresh with the refresh_token in the body and return the new access_token.
2. WHEN the refresh endpoint returns a 401 status, THE Auth_Remote_DataSource SHALL signal that the refresh_token is expired or invalid.
3. IF the refresh_token is expired or invalid, THEN THE Auth_Repository SHALL clear the persisted session and emit a null auth state (forcing re-login).

### Requirement 3: Dio Token Interceptor

**User Story:** As a developer, I want a Dio interceptor that attaches the Bearer token to all outgoing requests and retries with a fresh token on 401, so that authenticated API calls are handled transparently without manual token management in every datasource.

#### Acceptance Criteria

1. THE Token_Interceptor SHALL add an Authorization header with the format "Bearer <access_token>" to every outgoing HTTP request that targets the backend base URL.
2. WHEN a response with status 401 is received, THE Token_Interceptor SHALL attempt to refresh the access_token using the stored refresh_token before retrying the original request exactly once.
3. WHEN the token refresh succeeds during a retry, THE Token_Interceptor SHALL update the persisted access_token in local storage and retry the original request with the new token.
4. IF the token refresh fails during a retry, THEN THE Token_Interceptor SHALL reject the request with the original 401 error and trigger a session clear (logout).
5. WHILE a token refresh is in progress, THE Token_Interceptor SHALL queue concurrent 401-failing requests and resolve them with the new token once the refresh completes, avoiding multiple simultaneous refresh calls.

### Requirement 4: Register Flow with Auto-Login

**User Story:** As a new user, I want to be automatically logged in after a successful registration, so that I do not have to enter my credentials a second time.

#### Acceptance Criteria

1. WHEN the backend returns a 201 response to the registration request, THE Auth_Remote_DataSource SHALL extract the user id (UUID) and email from the response body.
2. WHEN registration succeeds, THE Auth_Remote_DataSource SHALL immediately call the login endpoint with the same credentials to obtain access_token and refresh_token.
3. WHEN the auto-login after registration succeeds, THE Auth_Repository SHALL persist the full session (id, email, access_token, refresh_token) and emit the authenticated AppUser state.

### Requirement 5: Real User ID from Backend

**User Story:** As a developer, I want the AppUser entity to carry the real UUID assigned by the backend, so that subsequent API calls referencing the user ID are correct.

#### Acceptance Criteria

1. WHEN a login is performed, THE Auth_Remote_DataSource SHALL obtain the user ID from the registration response or a prior register call, and associate it with the session.
2. THE AppUserDto SHALL map the "id" field from the backend registration response as a UUID string to the AppUser entity.
3. THE Local_Auth_DataSource SHALL persist and restore the backend-provided UUID as the user ID, replacing the previously hardcoded value.

### Requirement 6: Error Handling

**User Story:** As a user, I want clear feedback when authentication fails, so that I know whether my credentials are wrong or my email is already taken.

#### Acceptance Criteria

1. WHEN the login endpoint returns a 401 status, THE Auth_Remote_DataSource SHALL throw an InvalidCredentials failure.
2. WHEN the register endpoint returns a 409 status, THE Auth_Remote_DataSource SHALL throw an EmailAlreadyExists failure.
3. WHEN the register endpoint returns a 422 status, THE Auth_Remote_DataSource SHALL throw a ValidationError failure containing the detail message from the response body.
4. IF an unexpected network error occurs during any auth operation, THEN THE Auth_Remote_DataSource SHALL throw a NetworkError failure with the underlying error message.

### Requirement 7: Sign-Out Clears Full Session

**User Story:** As a user, I want signing out to remove all persisted credentials including both tokens, so that no stale authentication data remains in the browser.

#### Acceptance Criteria

1. WHEN the user signs out, THE Local_Auth_DataSource SHALL remove the access_token, refresh_token, user ID, and email from local storage.
2. WHEN the user signs out, THE Auth_Repository SHALL emit a null auth state and clear the in-memory current user reference.
3. WHEN the user signs out, THE Token_Interceptor SHALL cease attaching the Authorization header to subsequent requests until a new login occurs.
