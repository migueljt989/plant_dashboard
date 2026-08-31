# Implementation Plan: Irrigation Control

## Overview

Implementación del feature de control de riego siguiendo la arquitectura Clean Architecture + Repository/DataSource del proyecto. Se construye en orden de dependencias: dominio primero (entidades y contratos), luego infraestructura (DTOs, DataSource, Repository), y finalmente presentación (providers, controller, page y widgets). La ruta se registra al final para integrar todo.

## Tasks

- [x] 1. Domain layer — Entities and repository contract
  - [x] 1.1 Create IrrigationSession entity
    - Create `lib/domain/entities/irrigation_session.dart`
    - Immutable class with fields: id (String), deviceId (String), startedAt (DateTime), endedAt (DateTime?), durationSeconds (int?), stopReason (String?)
    - Constructor with required/optional named parameters
    - _Requirements: 1.1_

  - [x] 1.2 Create IrrigationStatus entity
    - Create `lib/domain/entities/irrigation_status.dart`
    - Immutable class with fields: connected (bool), irrigating (bool), sessionStartedAt (DateTime?)
    - _Requirements: 2.1_

  - [x] 1.3 Create IrrigationCommandResponse entity
    - Create `lib/domain/entities/irrigation_command_response.dart`
    - Immutable class with fields: status (String — "started"|"stopped"), cameraDeviceId (String?), cameraStreamingAvailable (bool)
    - _Requirements: 3.1_

  - [x] 1.4 Create IrrigationRepository abstract contract
    - Create `lib/domain/repositories/irrigation_repository.dart`
    - Define methods: startIrrigation(String deviceId), stopIrrigation(String deviceId), getStatus(String deviceId), getHistory(String deviceId, {int limit, int offset})
    - Return types use domain entities and existing PaginatedResponse generic
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 2. Infrastructure layer — DTOs
  - [x] 2.1 Create IrrigationSessionDto with fromJson/toJson/toEntity
    - Create `lib/infrastructure/models/irrigation_session_dto.dart`
    - Manual JSON serialization mapping snake_case keys to camelCase fields
    - `fromJson` throws FormatException on missing required fields (id, device_id, started_at) or incorrect types
    - `toJson` produces snake_case keys including nullables explicitly
    - `toEntity()` parses ISO-8601 strings into DateTime instances
    - _Requirements: 1.2, 1.3, 1.4, 1.5, 1.6_

  - [ ]* 2.2 Write property test for IrrigationSessionDto round-trip serialization
    - **Property 1: IrrigationSessionDto round-trip serialization**
    - **Validates: Requirements 1.5**

  - [x] 2.3 Create IrrigationStatusDto with fromJson/toJson/toEntity
    - Create `lib/infrastructure/models/irrigation_status_dto.dart`
    - Manual JSON serialization mapping snake_case keys
    - `fromJson` throws FormatException on missing required fields (connected, irrigating) or incorrect types
    - `fromJson` throws FormatException if session_started_at is non-null and not valid ISO-8601
    - `toEntity()` parses sessionStartedAt ISO-8601 string when non-null
    - _Requirements: 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

  - [ ]* 2.4 Write property test for IrrigationStatusDto round-trip serialization
    - **Property 2: IrrigationStatusDto round-trip serialization**
    - **Validates: Requirements 2.5**

  - [x] 2.5 Create IrrigationCommandResponseDto with fromJson/toJson/toEntity
    - Create `lib/infrastructure/models/irrigation_command_response_dto.dart`
    - Manual JSON serialization mapping snake_case keys
    - `fromJson` throws FormatException on missing required fields (status, camera_streaming_available) or incorrect types
    - `fromJson` throws FormatException if status is not "started" or "stopped"
    - `toEntity()` preserves all field values directly
    - _Requirements: 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

  - [ ]* 2.6 Write property test for IrrigationCommandResponseDto round-trip serialization
    - **Property 3: IrrigationCommandResponseDto round-trip serialization**
    - **Validates: Requirements 3.5**

  - [ ]* 2.7 Write property test for invalid JSON rejection across all DTOs
    - **Property 4: Invalid JSON rejection**
    - **Validates: Requirements 1.6, 2.6, 3.6**

- [x] 3. Infrastructure layer — DataSource contract and backend implementation
  - [x] 3.1 Create IrrigationDataSource abstract contract
    - Create `lib/infrastructure/datasources/irrigation/irrigation_datasource.dart`
    - Define methods: startIrrigation(String deviceId), stopIrrigation(String deviceId), fetchStatus(String deviceId), fetchHistory(String deviceId, {required int limit, required int offset})
    - Return types are DTOs and PaginatedResponse<IrrigationSessionDto>
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [x] 3.2 Create IrrigationDataSourceBackend implementation
    - Create `lib/infrastructure/datasources/irrigation/irrigation_datasource_backend.dart`
    - Receives authenticated Dio instance via constructor
    - Validates deviceId non-empty (throws ArgumentError)
    - Validates pagination params: limit 1–100, offset >= 0 (throws ArgumentError)
    - Maps HTTP errors: 404→NotFoundFailure, 401→SessionExpiredFailure, other→NetworkFailure
    - Implements POST `/irrigation/{device_id}/start`, POST `/irrigation/{device_id}/stop`, GET `/irrigation/{device_id}/status`, GET `/irrigation/{device_id}/history?limit=X&offset=Y`
    - _Requirements: 4.5, 4.6, 4.7, 4.8, 4.9, 4.10, 4.11, 4.12, 4.13_

  - [ ]* 3.3 Write property test for invalid pagination parameters rejection
    - **Property 5: Invalid pagination parameters rejection**
    - **Validates: Requirements 4.11**

- [x] 4. Infrastructure layer — Repository implementation
  - [x] 4.1 Create IrrigationRepositoryImpl
    - Create `lib/infrastructure/repositories/irrigation_repository_impl.dart`
    - Receives IrrigationDataSource via constructor
    - Delegates to datasource methods, maps DTOs to entities via `toEntity()`
    - For getHistory, maps each IrrigationSessionDto item to entity preserving pagination metadata
    - Propagates failures (NetworkFailure, NotFoundFailure, SessionExpiredFailure) without wrapping
    - _Requirements: 5.5, 5.6, 5.7_

- [x] 5. Checkpoint — Domain and infrastructure layers complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Presentation layer — State model and providers
  - [x] 6.1 Create IrrigationState model
    - Create `lib/presentation/providers/irrigation/irrigation_state.dart`
    - Immutable class with fields: status (IrrigationStatus), lastCommandResponse (IrrigationCommandResponse?), history (List<IrrigationSession>), hasMore (bool), consecutiveFailures (int, default 0), isCommandInProgress (bool, default false)
    - Computed getter `isStale => consecutiveFailures >= 3`
    - `copyWith` method for immutable state updates
    - _Requirements: 9.6, 11.4_

  - [ ]* 6.2 Write property test for consecutive failure count determines staleness
    - **Property 6: Consecutive failure count determines staleness**
    - **Validates: Requirements 9.6**

  - [x] 6.3 Create irrigation providers (datasource, repository, device)
    - Create `lib/presentation/providers/irrigation/irrigation_providers.dart`
    - `irrigationDataSourceProvider`: Provider returning IrrigationDataSourceBackend with authenticatedDioProvider
    - `irrigationRepositoryProvider`: Provider returning IrrigationRepositoryImpl with datasource
    - `irrigationDeviceProvider`: Provider that watches devicesControllerProvider and exposes first device with type DeviceType.irrigation (or null)
    - `irrigationControllerProvider`: AsyncNotifierProvider.autoDispose declaration
    - _Requirements: 11.1, 11.2, 11.3, 11.4_

- [x] 7. Presentation layer — IrrigationController
  - [x] 7.1 Implement IrrigationController (autoDispose AsyncNotifier)
    - Create `lib/presentation/providers/irrigation/irrigation_controller.dart`
    - `build()`: read irrigationDeviceProvider, throw if null; Future.wait([getStatus, getHistory(limit:20, offset:0)]); start polling timer; start duration timer if irrigating
    - `ref.onDispose`: cancel poll timer and duration timer
    - `_startPolling()`: Timer.periodic(10s) calling `_poll()`
    - `_poll()`: fetchStatus, on success reset consecutiveFailures and update state (including irrigating transition), on failure increment consecutiveFailures
    - `startIrrigation()`: set isCommandInProgress=true, call repo.startIrrigation, store response, refresh status, reset poll timer, handle duration timer start
    - `stopIrrigation()`: set isCommandInProgress=true, call repo.stopIrrigation, store response, refresh status, reset poll timer, cancel duration timer
    - `loadMoreHistory()`: calculate next offset, fetch next page, append to history, update hasMore
    - Duration timer: Timer.periodic(1s) that triggers state notify for elapsed time recalculation
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 11.5, 11.6, 11.7, 11.8, 11.9_

  - [ ]* 7.2 Write property test for poll status transition updates controller state
    - **Property 7: Poll status transition updates controller state**
    - **Validates: Requirements 9.2**

- [x] 8. Checkpoint — Providers and controller complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Presentation layer — IrrigationPage and widgets
  - [x] 9.1 Create IrrigationStatusCard widget
    - Create `lib/presentation/pages/irrigation/widgets/irrigation_status_card.dart`
    - Green dot when connected, red dot when disconnected
    - Animated pulsing water-drop icon when irrigating
    - Elapsed duration formatted "MM:SS" (from sessionStartedAt relative to now, updated by duration timer)
    - Static grey water-drop icon + "Listo" when connected and not irrigating
    - "Dispositivo desconectado" text when disconnected
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.7_

  - [x] 9.2 Create IrrigationControls widget
    - Create `lib/presentation/pages/irrigation/widgets/irrigation_controls.dart`
    - "Iniciar Riego" button when connected and not irrigating
    - "Detener Riego" button when connected and irrigating
    - Confirmation dialog on start press (prevent accidental pump activation)
    - Loading indicator on button while command in progress, button disabled
    - Disabled controls when device disconnected
    - Error SnackBar on command failure (visible up to 8 seconds)
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 7.10_

  - [x] 9.3 Create CameraStreamLink widget
    - Create `lib/presentation/pages/irrigation/widgets/camera_stream_link.dart`
    - "Ver Cámara en Vivo" button visible only when irrigating + cameraStreamingAvailable + cameraDeviceId non-null
    - Navigates to `/camaras/stream/:cameraDeviceId` on tap
    - Hidden when not irrigating or camera not available
    - Persists if navigating back and still irrigating (uses stored cameraDeviceId from state)
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

  - [x] 9.4 Create IrrigationHistoryList widget
    - Create `lib/presentation/pages/irrigation/widgets/irrigation_history_list.dart`
    - Display sessions in reverse chronological order
    - Each session shows: start time "dd/MM/yyyy HH:mm", end time or "En progreso", duration "Xm Ys" or "—", stop reason if non-null
    - "Load more" button when hasMore is true
    - Loading indicator while fetching
    - Error state with retry button
    - Empty state message when no sessions exist
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7_

  - [x] 9.5 Create StaleDateBanner widget
    - Create `lib/presentation/pages/irrigation/widgets/stale_data_banner.dart`
    - Visible when state.isStale (consecutiveFailures >= 3)
    - Displays warning that data may be outdated
    - _Requirements: 9.6_

  - [x] 9.6 Create IrrigationPage (main composition)
    - Create `lib/presentation/pages/irrigation/irrigation_page.dart`
    - ConsumerWidget that watches irrigationControllerProvider
    - Handles AsyncValue states: loading (CircularProgressIndicator), error (full-page error with retry), data (compose sub-widgets)
    - Handles null device state (message "no irrigation device registered")
    - Composes: IrrigationStatusCard, IrrigationControls, CameraStreamLink, StaleDateBanner, IrrigationHistoryList
    - _Requirements: 6.5, 6.6, 6.8, 10.8_

- [x] 10. Route registration and navigation integration
  - [x] 10.1 Register /riego route and nav item
    - Add `static const riego = '/riego';` to AppRoutes
    - Add GoRoute with path AppRoutes.riego as child of ShellRoute (after alerts), builder returns IrrigationPage
    - Add NavItem with label "Riego", water-drop outlined icon, route AppRoutes.riego, positioned after "Alertas" entry in kNavItems
    - Existing auth redirect guard applies automatically
    - _Requirements: 12.1, 12.2, 12.3, 12.4_

- [x] 11. Final checkpoint — Full feature integration
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- The project uses `glados` (or whichever PBT library is already in dev_dependencies) for property-based tests
- All code follows project conventions: snake_case files, PascalCase classes, Riverpod without codegen, manual JSON serialization

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3"] },
    { "id": 1, "tasks": ["1.4"] },
    { "id": 2, "tasks": ["2.1", "2.3", "2.5"] },
    { "id": 3, "tasks": ["2.2", "2.4", "2.6", "2.7", "3.1"] },
    { "id": 4, "tasks": ["3.2"] },
    { "id": 5, "tasks": ["3.3", "4.1"] },
    { "id": 6, "tasks": ["6.1", "6.3"] },
    { "id": 7, "tasks": ["6.2", "7.1"] },
    { "id": 8, "tasks": ["7.2"] },
    { "id": 9, "tasks": ["9.1", "9.2", "9.3", "9.4", "9.5"] },
    { "id": 10, "tasks": ["9.6"] },
    { "id": 11, "tasks": ["10.1"] }
  ]
}
```
