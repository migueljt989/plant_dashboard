# Requirements Document

## Introduction

Feature de control de riego para el panel IoT de jitomates cherry. Integra los endpoints REST del backend de irrigación para permitir al usuario iniciar/detener el riego de forma remota, ver el estado en tiempo real del dispositivo de irrigación (conectado/desconectado, regando o no, duración de la sesión actual), consultar el historial paginado de sesiones de riego, y recibir retroalimentación visual cuando el riego está activo. Cuando el backend indica que una cámara vinculada está disponible para streaming, la UI ofrece un enlace directo al stream en vivo. Sigue la arquitectura existente: Repository + DataSource con Riverpod, go_router y dio.

## Glossary

- **IrrigationDevice**: Dispositivo IoT de tipo "irrigation" capaz de activar y desactivar una bomba de riego de forma remota.
- **IrrigationStatus**: Estado actual del dispositivo de irrigación: si está conectado al sistema, si está regando, y la marca de tiempo del inicio de la sesión actual (si aplica).
- **IrrigationSession**: Registro histórico de una sesión de riego completada o en curso, con id, device_id, tiempos de inicio y fin, duración en segundos, y razón de paro.
- **IrrigationCommandResponse**: Respuesta del backend al iniciar o detener el riego, que incluye el estado resultante, el device_id de la cámara vinculada (si existe), y si el streaming de esa cámara está disponible.
- **IrrigationRepository**: Repositorio abstracto responsable de las operaciones de irrigación: iniciar, detener, consultar estado, y obtener historial de sesiones.
- **IrrigationDataSource**: Contrato abstracto del datasource que comunica con los endpoints `/irrigation` del backend.
- **IrrigationPage**: Página de UI en la ruta `/riego` que muestra el estado del dispositivo de irrigación, controles de inicio/paro, indicador animado de riego activo, enlace a cámara vinculada, y historial de sesiones.
- **PaginatedResponse**: Estructura genérica reutilizada que encapsula items con metadatos de paginación (total, limit, offset).

## Requirements

### Requirement 1: IrrigationSession Entity and DTO

**User Story:** As a developer, I want a domain entity and DTO that model an irrigation session from the backend, so that the irrigation feature has a proper domain representation for historical sessions.

#### Acceptance Criteria

1. THE IrrigationSession entity SHALL contain the fields: id (String), deviceId (String), startedAt (DateTime), endedAt (DateTime or null), durationSeconds (int or null), and stopReason (String or null).
2. THE IrrigationSessionDto SHALL parse a JSON object matching the `IrrigationSessionSchema` into an IrrigationSessionDto instance, mapping snake_case keys (id, device_id, started_at, ended_at, duration_seconds, stop_reason) to camelCase Dart fields, storing datetime values as ISO-8601 String in the DTO. Nullable keys (ended_at, duration_seconds, stop_reason) that are absent from the JSON object or explicitly set to null SHALL both result in null field values in the DTO.
3. THE IrrigationSessionDto SHALL convert to an IrrigationSession domain entity via a `toEntity()` method, parsing the startedAt ISO-8601 String field into a DateTime instance using `DateTime.parse()` and parsing endedAt into a DateTime instance when non-null.
4. THE IrrigationSessionDto SHALL serialize back to a JSON map via a `toJson()` method producing the same snake_case keys as the backend schema, including nullable keys set to null explicitly in the output map.
5. FOR ALL valid IrrigationSessionDto instances, calling `toJson()` and then `IrrigationSessionDto.fromJson()` on the result SHALL produce an IrrigationSessionDto with identical field values (round-trip serialization property).
6. IF the JSON object passed to `IrrigationSessionDto.fromJson()` is missing a required field (id, device_id, started_at) or contains a value of incorrect type for any field, THEN THE IrrigationSessionDto SHALL throw a FormatException indicating which field caused the parsing failure.

### Requirement 2: IrrigationStatus Entity and DTO

**User Story:** As a developer, I want a domain entity and DTO that model the current irrigation device status from the backend, so that the UI can display whether the device is connected and irrigating.

#### Acceptance Criteria

1. THE IrrigationStatus entity SHALL contain the fields: connected (bool), irrigating (bool), and sessionStartedAt (DateTime or null).
2. WHEN a JSON map is passed to `IrrigationStatusDto.fromJson()`, THE IrrigationStatusDto SHALL map the snake_case keys (connected, irrigating, session_started_at) to camelCase Dart fields, storing session_started_at as an ISO-8601 String (or null) in the DTO.
3. WHEN `toEntity()` is called on an IrrigationStatusDto, THE IrrigationStatusDto SHALL return an IrrigationStatus domain entity, parsing the sessionStartedAt ISO-8601 String into a DateTime instance when non-null, and setting it to null when the DTO field is null.
4. THE IrrigationStatusDto SHALL serialize back to a JSON map via a `toJson()` method producing the same snake_case keys as the backend schema (connected, irrigating, session_started_at).
5. FOR ALL valid IrrigationStatusDto instances, calling `toJson()` and then `IrrigationStatusDto.fromJson()` on the result SHALL produce an IrrigationStatusDto with identical field values (round-trip serialization property).
6. IF the JSON object passed to `IrrigationStatusDto.fromJson()` is missing a required field (connected, irrigating) or contains a value of incorrect type, THEN THE IrrigationStatusDto SHALL throw a FormatException indicating the parsing failure reason.
7. IF the session_started_at field in the JSON object is non-null and is not a valid ISO-8601 datetime string, THEN THE IrrigationStatusDto SHALL throw a FormatException indicating the invalid datetime format.

### Requirement 3: IrrigationCommandResponse Entity and DTO

**User Story:** As a developer, I want a domain entity and DTO that model the response from start/stop irrigation commands, so that the UI can update state and optionally link to a camera stream.

#### Acceptance Criteria

1. THE IrrigationCommandResponse entity SHALL contain the fields: status (String, restricted to the values "started" or "stopped"), cameraDeviceId (String or null), and cameraStreamingAvailable (bool).
2. THE IrrigationCommandResponseDto SHALL parse a JSON object matching the `IrrigationCommandResponseSchema` into an IrrigationCommandResponseDto instance, mapping snake_case keys (status, camera_device_id, camera_streaming_available) to camelCase Dart fields, where a JSON `null` value or absent key for `camera_device_id` maps to a null `cameraDeviceId` field.
3. THE IrrigationCommandResponseDto SHALL convert to an IrrigationCommandResponse domain entity via a `toEntity()` method, preserving all field values.
4. THE IrrigationCommandResponseDto SHALL serialize back to a JSON map via a `toJson()` method producing the same snake_case keys as the backend schema, representing a null `cameraDeviceId` as a JSON `null` value for the `camera_device_id` key.
5. FOR ALL valid IrrigationCommandResponseDto instances, calling `toJson()` and then `IrrigationCommandResponseDto.fromJson()` on the result SHALL produce an IrrigationCommandResponseDto with identical field values (round-trip serialization property).
6. IF the JSON object passed to `IrrigationCommandResponseDto.fromJson()` is missing a required field (status, camera_streaming_available) or contains a value of incorrect type, THEN THE IrrigationCommandResponseDto SHALL throw a FormatException indicating which field is missing or has the wrong type.
7. IF the JSON object passed to `IrrigationCommandResponseDto.fromJson()` contains a `status` value other than "started" or "stopped", THEN THE IrrigationCommandResponseDto SHALL throw a FormatException indicating that the status value is not recognized.

### Requirement 4: Irrigation DataSource Contract and Backend Implementation

**User Story:** As a developer, I want an abstract datasource contract and a REST implementation for irrigation operations, so that the irrigation data layer is decoupled from the HTTP client.

#### Acceptance Criteria

1. THE IrrigationDataSource contract SHALL define a method `startIrrigation` that accepts a deviceId (String) and returns an IrrigationCommandResponseDto.
2. THE IrrigationDataSource contract SHALL define a method `stopIrrigation` that accepts a deviceId (String) and returns an IrrigationCommandResponseDto.
3. THE IrrigationDataSource contract SHALL define a method `fetchStatus` that accepts a deviceId (String) and returns an IrrigationStatusDto.
4. THE IrrigationDataSource contract SHALL define a method `fetchHistory` that accepts a deviceId (String) and pagination params (limit: int, offset: int) and returns a PaginatedResponse of IrrigationSessionDto.
5. WHEN `startIrrigation` is called, THE IrrigationDataSourceBackend implementation SHALL send a POST request to `/irrigation/{device_id}/start` using the authenticated Dio instance.
6. WHEN `stopIrrigation` is called, THE IrrigationDataSourceBackend implementation SHALL send a POST request to `/irrigation/{device_id}/stop` using the authenticated Dio instance.
7. WHEN `fetchStatus` is called, THE IrrigationDataSourceBackend implementation SHALL send a GET request to `/irrigation/{device_id}/status` using the authenticated Dio instance.
8. WHEN `fetchHistory` is called, THE IrrigationDataSourceBackend implementation SHALL send a GET request to `/irrigation/{device_id}/history` with limit and offset query parameters using the authenticated Dio instance.
9. IF the backend responds with a 404 status, THEN THE IrrigationDataSourceBackend SHALL throw a NotFoundFailure, taking priority over any concurrent network error condition.
10. IF the backend responds with a network error or a non-404 unexpected HTTP status (e.g., 500), THEN THE IrrigationDataSourceBackend SHALL throw a NetworkFailure.
11. IF `fetchHistory` is called with a limit less than 1 or greater than 100, or with an offset less than 0, THEN THE IrrigationDataSourceBackend SHALL throw an ArgumentError without making a network request.
12. IF any method is called with an empty deviceId (empty string), THEN THE IrrigationDataSourceBackend SHALL throw an ArgumentError without making a network request.
13. IF the backend responds with a 401 status, THEN THE IrrigationDataSourceBackend SHALL throw a SessionExpiredFailure.

### Requirement 5: Irrigation Repository

**User Story:** As a developer, I want an abstract IrrigationRepository and its implementation, so that the presentation layer can perform irrigation operations without knowing about HTTP details.

#### Acceptance Criteria

1. THE IrrigationRepository contract SHALL define a method `startIrrigation` that accepts a deviceId (String) and returns an IrrigationCommandResponse entity.
2. THE IrrigationRepository contract SHALL define a method `stopIrrigation` that accepts a deviceId (String) and returns an IrrigationCommandResponse entity.
3. THE IrrigationRepository contract SHALL define a method `getStatus` that accepts a deviceId (String) and returns an IrrigationStatus entity.
4. THE IrrigationRepository contract SHALL define a method `getHistory` that accepts a deviceId (String) and pagination params (limit: int defaulting to 20 range 1–100, offset: int defaulting to 0) and returns a PaginatedResponse of IrrigationSession entities.
5. WHEN a method that returns a single entity (startIrrigation, stopIrrigation, getStatus) is called, THE IrrigationRepositoryImpl SHALL delegate to the corresponding IrrigationDataSource method and map the returned DTO to the domain entity via its `toEntity()` method.
6. WHEN `getHistory` is called, THE IrrigationRepositoryImpl SHALL delegate to `IrrigationDataSource.fetchHistory()` and map each IrrigationSessionDto item to an IrrigationSession entity via `toEntity()`, preserving the pagination metadata (total, limit, offset).
7. IF the IrrigationDataSource throws a Failure (NetworkFailure, NotFoundFailure, SessionExpiredFailure), THEN THE IrrigationRepositoryImpl SHALL propagate the Failure to the caller without wrapping or transforming it.

### Requirement 6: Irrigation Control Page — Status Display

**User Story:** As a user, I want to see the current status of my irrigation device on a dedicated page, so that I can know if the device is connected and whether it is currently watering.

#### Acceptance Criteria

1. WHEN the user navigates to `/riego`, THE IrrigationPage SHALL display the connection status of the irrigation device using a colored dot indicator: green when connected, red when disconnected.
2. WHEN the irrigation device is connected and currently irrigating, THE IrrigationPage SHALL display an animated pulsing water-drop icon signaling that irrigation is active.
3. WHEN the irrigation device is connected and currently irrigating, THE IrrigationPage SHALL display the elapsed duration of the current session formatted as "MM:SS" (minutes and seconds), calculated from the session_started_at timestamp relative to DateTime.now(), updating every second via a periodic Timer.
4. WHEN the irrigation device is connected and not irrigating, THE IrrigationPage SHALL display a static water-drop icon in grey and the text "Listo" indicating the device is ready but not active.
5. WHILE the status is loading, THE IrrigationPage SHALL display a CircularProgressIndicator centered in the status area.
6. IF the status request fails, THEN THE IrrigationPage SHALL display an error message with a retry button. THE retry SHALL invalidate both the devicesControllerProvider and the irrigationControllerProvider, because when the failure occurred while loading the device list, invalidating only the controller would not re-fetch it and the retry would have no effect.
7. WHEN the irrigation device is disconnected (connected == false), THE IrrigationPage SHALL display the text "Dispositivo desconectado" and disable the start/stop controls.
8. IF the device list loaded successfully and contains no irrigation device, THEN THE IrrigationPage SHALL display a message indicating that no irrigation device is registered. THE page SHALL distinguish this case by type (a dedicated NoIrrigationDeviceException) and SHALL NOT identify it by matching text inside the error message, which breaks on any change of wording or language. A network or authentication failure SHALL instead render the error state of criterion 6 above, with its real message and a retry button.

### Requirement 7: Irrigation Control Page — Start and Stop Controls

**User Story:** As a user, I want to start and stop irrigation from the dashboard, so that I can remotely control the watering of my plants.

#### Acceptance Criteria

1. WHEN the irrigation device is connected and not irrigating, THE IrrigationPage SHALL display an enabled "Iniciar Riego" button.
2. WHEN the irrigation device is connected and currently irrigating, THE IrrigationPage SHALL display an enabled "Detener Riego" button.
3. WHEN the user presses the "Iniciar Riego" button, THE IrrigationPage SHALL display a confirmation dialog requesting the user to confirm the irrigation start before sending the command, to prevent accidental activation of the water pump.
4. WHEN the user confirms the start action in the confirmation dialog, THE system SHALL send a start command to the backend using IrrigationRepository.startIrrigation with the deviceId obtained from the irrigationDeviceProvider.
5. WHEN the user presses the "Detener Riego" button, THE system SHALL send a stop command to the backend using IrrigationRepository.stopIrrigation with the deviceId obtained from the irrigationDeviceProvider.
6. WHILE a start or stop command is in progress, THE IrrigationPage SHALL disable the control button and display a loading indicator on the button to prevent duplicate submissions.
7. WHEN a start command succeeds with status "started", THE IrrigationPage SHALL update the UI to reflect the irrigating state (show animated indicator, start duration counter, switch to stop button).
8. WHEN a stop command succeeds with status "stopped", THE IrrigationPage SHALL update the UI to reflect the idle state (remove animated indicator, stop duration counter, switch to start button).
9. IF a start or stop command fails, THEN THE IrrigationPage SHALL display an error notification with the failure reason, keep the notification visible until the user dismisses it or for a maximum of 8 seconds, and restore the button to its previous enabled state.
10. IF a start or stop command succeeds but the response status is neither "started" nor "stopped", THEN THE IrrigationPage SHALL treat the response as a failure, display an error notification indicating an unexpected response, and restore the button to its previous enabled state.

### Requirement 8: Camera Stream Link on Irrigation Start

**User Story:** As a user, I want to see a link to the live camera stream when irrigation starts and a camera is available, so that I can visually monitor my plants while watering.

#### Acceptance Criteria

1. WHEN a start command succeeds and the response includes cameraStreamingAvailable equal to true and a non-null cameraDeviceId, THE IrrigationPage SHALL display a "Ver Cámara en Vivo" button adjacent to the irrigation status area.
2. WHEN the user taps the "Ver Cámara en Vivo" button, THE IrrigationPage SHALL navigate to `/camaras/stream/:cameraDeviceId` using the cameraDeviceId from the command response.
3. WHEN the irrigation is stopped or the status shows irrigating is false, THE IrrigationPage SHALL hide the "Ver Cámara en Vivo" button.
4. IF the start command response has cameraStreamingAvailable equal to false or cameraDeviceId is null, THEN THE IrrigationPage SHALL NOT display any camera stream link.
5. WHEN the user navigates back to the IrrigationPage after having started irrigation and the status still shows irrigating is true, THE IrrigationPage SHALL display the "Ver Cámara en Vivo" button if a cameraDeviceId was previously stored in the controller state.

### Requirement 9: Status Polling

**User Story:** As a user, I want the irrigation status to refresh periodically, so that I can see status changes that happen outside the dashboard (e.g., automatic stop by timer).

#### Acceptance Criteria

1. WHILE the IrrigationPage is visible, THE system SHALL poll the irrigation status endpoint every 10 seconds to detect external state changes.
2. WHEN a poll response indicates a change in the `irrigating` boolean (true to false or false to true), THE IrrigationPage SHALL update the displayed irrigation state and elapsed time to reflect the new values without requiring manual user interaction.
3. WHEN the user manually triggers a start or stop command, THE system SHALL fetch the latest status within 1 second of the command completing successfully, and reset the 10-second polling timer from that point.
4. WHEN the user navigates away from the IrrigationPage route (the provider is disposed), THE system SHALL cancel the polling timer so that no further polling requests are made.
5. IF a single polling request fails, THEN THE system SHALL retain the previously displayed status, skip the failed poll, and attempt the next poll at the normal 10-second interval without displaying an error to the user.
6. IF 3 consecutive polling requests fail, THEN THE system SHALL display a stale-data indicator on the IrrigationPage informing the user that the displayed status may be outdated, and SHALL guarantee that polling remains active at the normal 10-second interval until the provider is disposed.

### Requirement 10: Irrigation Session History

**User Story:** As a user, I want to see a paginated list of past irrigation sessions, so that I can review how often and how long my plants have been watered.

#### Acceptance Criteria

1. THE IrrigationPage SHALL display a session history section below the status and controls area, showing past irrigation sessions in reverse chronological order (most recent first).
2. THE IrrigationPage SHALL display each session with: start time (formatted as "dd/MM/yyyy HH:mm"), end time (formatted as "dd/MM/yyyy HH:mm" or "En progreso" if null), duration (formatted as "Xm Ys" where X is minutes and Y is seconds, or "—" if null), and stop reason (displayed if non-null, omitted otherwise).
3. THE IrrigationPage SHALL support pagination via a "Load more" button displayed below the session list, fetching 20 sessions per request.
4. WHEN the total number of sessions returned by the API exceeds the current offset plus limit, THE IrrigationPage SHALL display the "Load more" button; otherwise, the button SHALL be hidden.
5. WHILE history sessions are loading and no error has occurred, THE IrrigationPage SHALL display a loading indicator in the history section. THE loading indicator SHALL be hidden immediately when a request fails.
6. IF the history request fails, THEN THE IrrigationPage SHALL display an error message in the history section with a retry button that re-sends the last request preserving the current offset.
7. IF no irrigation sessions exist, THEN THE IrrigationPage SHALL display an empty-state message indicating that no irrigation history is available.
8. WHEN the IrrigationPage first loads, THE system SHALL fetch the initial page of history (offset 0, limit 20) concurrently with the status request.

### Requirement 11: Riverpod Providers for Irrigation Feature

**User Story:** As a developer, I want Riverpod providers that wire the irrigation infrastructure and expose state to the UI, so that the irrigation page can consume data reactively.

#### Acceptance Criteria

1. THE irrigationDataSourceProvider SHALL be a Provider that provides an IrrigationDataSourceBackend instance using the authenticatedDioProvider.
2. THE irrigationRepositoryProvider SHALL be a Provider that provides an IrrigationRepositoryImpl instance using the irrigationDataSourceProvider.
3. THE irrigationDeviceProvider SHALL be a FutureProvider that awaits the devicesControllerProvider and exposes the first device whose type is DeviceType.irrigation, or null if the device list loaded successfully and contains no irrigation device. It SHALL NOT collapse "list still loading" or "list failed to load" into null: while the list is loading the provider SHALL remain in a loading state, and if the list fails the provider SHALL propagate that error unchanged, so that a network or authentication failure is never reported to the user as an absent device.
4. THE irrigationControllerProvider SHALL be an autoDispose AsyncNotifierProvider that exposes an AsyncValue containing the current IrrigationStatus, the last IrrigationCommandResponse (or null if no command has been issued), and session history as a list with a boolean flag indicating whether more pages are available.
5. WHEN the irrigationControllerProvider is first built and irrigationDeviceProvider returns a non-null device, THE provider SHALL fetch the current status and the first page of history (20 items) concurrently, and SHALL emit an error state if either operation fails.
6. THE absence of an irrigation device SHALL be treated as a normal, expected state and NOT as an error state. THE IrrigationPage SHALL resolve irrigationDeviceProvider first and SHALL only watch the irrigationControllerProvider once a non-null device is confirmed, so that the controller is never built when no device exists.

   Rationale (regression guard): irrigationControllerProvider is autoDispose, and an autoDispose provider does not retain the error state produced by a throwing `build()`. It is disposed and immediately recreated by the page's active listener, which throws again, producing an infinite rebuild loop that saturates the main isolate and leaves the UI stuck on a loading indicator. Modeling a routine condition as an error is what triggers this, so the controller MUST NOT throw to signal an absent device.
7. WHEN a start or stop command succeeds via the irrigationControllerProvider, THE irrigationControllerProvider SHALL store the IrrigationCommandResponse and trigger a status refresh without waiting for the next polling cycle.
8. WHEN the user invokes loadMoreHistory on the irrigationControllerProvider, THE provider SHALL fetch the next page of 20 history items and append them to the existing list.
9. WHILE the irrigationControllerProvider has at least one active listener and holds a successful data state, THE provider SHALL poll the irrigation status every 10 seconds and cancel the polling timer on dispose.

### Requirement 12: Go Router Integration

**User Story:** As a developer, I want a route registered for the irrigation control page, so that users can navigate to it via the side menu and deep links.

#### Acceptance Criteria

1. THE router SHALL register a `GoRoute` with path `AppRoutes.riego` as a child of the existing ShellRoute, with a builder that returns `IrrigationPage`.
2. THE `kNavItems` list SHALL include a `NavItem` with label "Riego", a water-drop outlined icon, and route `AppRoutes.riego`, positioned after the "Alertas" entry.
3. IF an unauthenticated user attempts to access `/riego`, THEN THE router SHALL redirect to the login page via the existing auth redirect guard.
4. THE `AppRoutes` class SHALL define a static string constant named `riego` with value `'/riego'`.
