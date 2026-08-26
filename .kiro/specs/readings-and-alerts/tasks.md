# Implementation Plan: Readings and Alerts

## Overview

Implement the readings history (`/lecturas`) and alerts (`/alertas`) pages for the IoT dashboard. This follows the existing clean architecture pattern: domain entities → abstract repositories → datasource contracts with DTOs → backend implementations with authenticated Dio → Riverpod providers → UI pages. The implementation is broken into incremental waves starting from domain enums/entities up through the presentation layer.

## Tasks

- [x] 1. Create domain enums and entities
  - [x] 1.1 Create AlertType enum
    - Create `lib/domain/entities/alert_type.dart` with values `breach`, `recovery`
    - Include `fromString(String)` static method with fallback to `breach`
    - Include `toBackendString()` method
    - _Requirements: 3.1_

  - [x] 1.2 Create BreachedBound enum
    - Create `lib/domain/entities/breached_bound.dart` with values `minOk`, `maxOk`
    - Include `fromString(String)` mapping from snake_case (`min_ok`, `max_ok`) with fallback to `minOk`
    - Include `toBackendString()` returning snake_case strings
    - _Requirements: 3.2_

  - [x] 1.3 Create DeliveryStatus enum
    - Create `lib/domain/entities/delivery_status.dart` with values `pending`, `sent`, `failed`, `skipped`
    - Include `fromString(String)` with fallback to `pending`
    - Include `toBackendString()` method
    - _Requirements: 3.3_

  - [x] 1.4 Create Reading entity
    - Create `lib/domain/entities/reading.dart` with fields: id, sensorId, sensorName, deviceId, metric (MetricType), unit, value, recordedAt
    - Use `const` constructor with all required fields
    - Import existing `MetricType` from the devices-and-sensors feature
    - _Requirements: 1.1_

  - [x] 1.5 Create Alert entity
    - Create `lib/domain/entities/alert.dart` with fields: id, sensorId, sensorName, deviceId, metric (MetricType), unit, alertType (AlertType), value, breachedBound (nullable), minOk (nullable), maxOk (nullable), triggeredAt, deliveryStatus
    - Use `const` constructor with required and optional fields
    - _Requirements: 2.1_

- [x] 2. Create generic infrastructure model and DTOs
  - [x] 2.1 Create PaginatedResponse generic model
    - Create `lib/infrastructure/models/paginated_response.dart`
    - Define generic class with fields: items (List<T>), total, limit, offset
    - Implement computed `hasMore` getter: `offset + items.length < total`
    - Implement `fromJson` factory that parses `pagination` and `items` from JSON using an `itemParser` callback
    - _Requirements: 4.1, 4.2, 4.3_

  - [x] 2.2 Create ReadingDto
    - Create `lib/infrastructure/models/reading_dto.dart`
    - Implement `fromJson(Map<String, dynamic>)` factory mapping snake_case keys
    - Implement `toJson()` returning snake_case keys
    - Implement `toEntity()` converting to Reading domain entity (parse metric via MetricType.fromString, recordedAt via DateTime.parse)
    - _Requirements: 1.2, 1.3, 1.4_

  - [x] 2.3 Create AlertDto
    - Create `lib/infrastructure/models/alert_dto.dart`
    - Implement `fromJson(Map<String, dynamic>)` factory mapping snake_case keys, handling nullable fields
    - Implement `toJson()` returning snake_case keys
    - Implement `toEntity()` converting to Alert domain entity using enum fromString methods
    - _Requirements: 2.2, 2.3, 2.4_

- [~] 3. Checkpoint - Verify domain and models compile
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Create repository contracts
  - [x] 4.1 Create ReadingsRepository contract
    - Create `lib/domain/repositories/readings_repository.dart`
    - Define abstract class with `getReadings(...)` returning `Future<PaginatedResponse<Reading>>` accepting optional filters + limit/offset
    - Define `getLatestReading(...)` returning `Future<Reading>` accepting optional filters
    - _Requirements: 7.1, 7.2_

  - [x] 4.2 Create AlertsRepository contract
    - Create `lib/domain/repositories/alerts_repository.dart`
    - Define abstract class with `getAlerts(...)` returning `Future<PaginatedResponse<Alert>>` accepting optional filters + limit/offset
    - _Requirements: 8.1_

- [x] 5. Create datasource contracts and implementations
  - [x] 5.1 Create ReadingsRemoteDataSource contract
    - Create `lib/infrastructure/datasources/readings/readings_remote_datasource.dart`
    - Define abstract class with `fetchReadings(...)` returning `Future<PaginatedResponse<ReadingDto>>` and `fetchLatestReading(...)` returning `Future<ReadingDto>`
    - _Requirements: 5.1, 5.2_

  - [x] 5.2 Create AlertsRemoteDataSource contract
    - Create `lib/infrastructure/datasources/alerts/alerts_remote_datasource.dart`
    - Define abstract class with `fetchAlerts(...)` returning `Future<PaginatedResponse<AlertDto>>`
    - _Requirements: 6.1_

  - [x] 5.3 Create ReadingsRemoteDataSourceBackend implementation
    - Create `lib/infrastructure/datasources/readings/readings_remote_datasource_backend.dart`
    - Inject authenticated Dio instance via constructor
    - Implement `fetchReadings`: GET `/readings` with query params, parse response with `PaginatedResponse.fromJson` + `ReadingDto.fromJson`
    - Implement `fetchLatestReading`: GET `/readings/latest` with query params, parse single ReadingDto
    - Handle DioException: 404 → throw NotFoundFailure, other errors → throw NetworkFailure
    - _Requirements: 5.3, 5.4, 5.5, 5.6_

  - [x] 5.4 Create AlertsRemoteDataSourceBackend implementation
    - Create `lib/infrastructure/datasources/alerts/alerts_remote_datasource_backend.dart`
    - Inject authenticated Dio instance via constructor
    - Implement `fetchAlerts`: GET `/alerts` with query params, parse response with `PaginatedResponse.fromJson` + `AlertDto.fromJson`
    - Handle DioException: throw NetworkFailure on errors
    - _Requirements: 6.2, 6.3_

- [ ] 6. Create repository implementations
  - [~] 6.1 Create ReadingsRepositoryImpl
    - Create `lib/infrastructure/repositories/readings_repository_impl.dart`
    - Inject `ReadingsRemoteDataSource` via constructor
    - Implement `getReadings`: delegate to datasource, map PaginatedResponse<ReadingDto> to PaginatedResponse<Reading> using `toEntity()`
    - Implement `getLatestReading`: delegate to datasource, map ReadingDto to Reading
    - _Requirements: 7.3, 7.4_

  - [~] 6.2 Create AlertsRepositoryImpl
    - Create `lib/infrastructure/repositories/alerts_repository_impl.dart`
    - Inject `AlertsRemoteDataSource` via constructor
    - Implement `getAlerts`: delegate to datasource, map PaginatedResponse<AlertDto> to PaginatedResponse<Alert> using `toEntity()`
    - _Requirements: 8.2_

- [~] 7. Checkpoint - Verify infrastructure layer compiles
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Create presentation filter and state models
  - [~] 8.1 Create ReadingsFilter model
    - Create `lib/presentation/providers/readings/readings_filter.dart`
    - Implement immutable class with optional fields: sensorId, deviceId, metric, from, to
    - Implement `copyWith` with clear flags for each nullable field
    - Implement `toQueryParams()` returning `Map<String, String>` with only non-null values
    - _Requirements: 9.2, 9.3_

  - [~] 8.2 Create AlertsFilter model
    - Create `lib/presentation/providers/alerts/alerts_filter.dart`
    - Implement immutable class with optional fields: sensorId, deviceId, metric, alertType, from, to
    - Implement `copyWith` with clear flags for each nullable field
    - Implement `toQueryParams()` returning `Map<String, String>` with only non-null values
    - _Requirements: 11.2, 11.3_

  - [~] 8.3 Create ReadingsState model
    - Create `lib/presentation/providers/readings/readings_state.dart`
    - Implement class with fields: items (List<Reading>), total, limit (default 50), offset (default 0), filter (ReadingsFilter), isLoadingMore (bool)
    - Implement computed `hasMore` getter and `copyWith` method
    - _Requirements: 9.7, 9.8, 12.3_

  - [~] 8.4 Create AlertsState model
    - Create `lib/presentation/providers/alerts/alerts_state.dart`
    - Implement class with fields: items (List<Alert>), total, limit (default 50), offset (default 0), filter (AlertsFilter), isLoadingMore (bool)
    - Implement computed `hasMore` getter and `copyWith` method
    - _Requirements: 11.8, 11.9, 13.3_

- [ ] 9. Create Riverpod providers
  - [~] 9.1 Create readings providers
    - Create `lib/presentation/providers/readings/readings_providers.dart`
    - Define `readingsDataSourceProvider`: Provider that returns ReadingsRemoteDataSourceBackend using `authenticatedDioProvider`
    - Define `readingsRepositoryProvider`: Provider that returns ReadingsRepositoryImpl using the datasource provider
    - Define `readingsControllerProvider`: AsyncNotifierProvider with ReadingsController extending AsyncNotifier<ReadingsState>
      - `build()`: fetch first page with default filter, return initial state
      - `applyFilters(ReadingsFilter)`: reset offset to 0, fetch, replace items
      - `loadMore()`: set isLoadingMore=true, fetch next page, append items, update offset
    - Define `latestReadingProvider`: FutureProvider.autoDispose that reads the current filter from readingsControllerProvider and fetches the latest reading
    - _Requirements: 12.1, 12.2, 12.3, 12.4_

  - [~] 9.2 Create alerts providers
    - Create `lib/presentation/providers/alerts/alerts_providers.dart`
    - Define `alertsDataSourceProvider`: Provider that returns AlertsRemoteDataSourceBackend using `authenticatedDioProvider`
    - Define `alertsRepositoryProvider`: Provider that returns AlertsRepositoryImpl using the datasource provider
    - Define `alertsControllerProvider`: AsyncNotifierProvider with AlertsController extending AsyncNotifier<AlertsState>
      - `build()`: fetch first page with default filter, return initial state
      - `applyFilters(AlertsFilter)`: reset offset to 0, fetch, replace items
      - `loadMore()`: set isLoadingMore=true, fetch next page, append items, update offset
    - _Requirements: 13.1, 13.2, 13.3_

- [~] 10. Checkpoint - Verify providers compile and wire correctly
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Implement ReadingsPage UI
  - [~] 11.1 Rewrite ReadingsPage
    - Rewrite `lib/presentation/pages/readings/readings_page.dart` replacing the placeholder
    - Add latest reading summary card at the top consuming `latestReadingProvider` (show loading placeholder, "sin datos" on null, sensor name + metric + value + unit + timestamp on data)
    - Add filter row with: device dropdown (from devicesControllerProvider), sensor dropdown (from sensorsControllerProvider), metric dropdown (MetricType values), date range picker (from/to)
    - Display readings in a DataTable/ListView with columns: sensor name, metric, value+unit, recorded_at
    - Add "Cargar más" button at bottom, visible when `hasMore` is true, triggers `loadMore()`
    - Show loading indicator during initial load, error message with retry button on failure
    - Wire filter changes to call `applyFilters()` on the readings controller
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8, 10.1, 10.2, 10.3, 10.4_

- [ ] 12. Implement AlertsPage UI
  - [~] 12.1 Rewrite AlertsPage
    - Rewrite `lib/presentation/pages/alerts/alerts_page.dart` replacing the placeholder
    - Add filter row with: device dropdown, sensor dropdown, metric dropdown, alert type dropdown (AlertType values), date range picker
    - Display alerts in a DataTable/ListView with columns: sensor name, metric, alert type, value+unit, breached bound + thresholds, triggered_at
    - Color-code rows: breach alerts with red/warning styling, recovery alerts with green/success styling
    - Show breached bound info: "Mín: X / Máx: Y" when breachedBound is present
    - Add "Cargar más" button at bottom, visible when `hasMore` is true
    - Show loading indicator during initial load, error message with retry button on failure
    - Wire filter changes to call `applyFilters()` on the alerts controller
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7, 11.8, 11.9_

- [~] 13. Final checkpoint - Verify full feature compiles
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 14. Property-based tests
  - [ ]* 14.1 Add glados PBT dependency
    - Add `glados` package to dev_dependencies in pubspec.yaml
    - Run `flutter pub get` to install
    - _Requirements: 1.4, 2.4_

  - [ ]* 14.2 Write property test for ReadingDto round-trip
    - **Property 1: ReadingDto round-trip serialization**
    - **Validates: Requirements 1.2, 1.3, 1.4**
    - Create test file `test/infrastructure/models/reading_dto_pbt_test.dart`
    - Generate arbitrary ReadingDto instances, verify `toJson()` → `fromJson()` → `toJson()` produces identical JSON maps

  - [ ]* 14.3 Write property test for AlertDto round-trip
    - **Property 2: AlertDto round-trip serialization**
    - **Validates: Requirements 2.2, 2.3, 2.4**
    - Create test file `test/infrastructure/models/alert_dto_pbt_test.dart`
    - Generate arbitrary AlertDto instances (including nullable fields), verify `toJson()` → `fromJson()` → `toJson()` produces identical JSON maps

  - [ ]* 14.4 Write property test for enum round-trips
    - **Property 3: Alert enum round-trip**
    - **Validates: Requirements 3.1, 3.2, 3.3**
    - Create test file `test/domain/entities/enums_pbt_test.dart`
    - For each enum (AlertType, BreachedBound, DeliveryStatus): verify `toBackendString()` → `fromString()` returns original value

  - [ ]* 14.5 Write property tests for PaginatedResponse
    - **Property 4: PaginatedResponse parsing preserves items and metadata**
    - **Property 5: PaginatedResponse hasMore correctness**
    - **Validates: Requirements 4.1, 4.2, 4.3**
    - Create test file `test/infrastructure/models/paginated_response_pbt_test.dart`
    - Generate arbitrary JSON with items array + pagination object, verify parsed instance preserves counts and metadata
    - Generate arbitrary offset/items.length/total combinations, verify `hasMore` equals `offset + items.length < total`

- [~] 15. Final checkpoint - All tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation between layers
- Property tests validate universal correctness properties from the design document
- The existing `MetricType` enum from the devices-and-sensors feature is reused (not recreated)
- Filter dropdowns for devices and sensors consume existing `devicesControllerProvider` and `sensorsControllerProvider`
- The `authenticatedDioProvider` from `lib/infrastructure/network/dio_provider.dart` is used for all HTTP calls
- `PaginatedResponse` needs a way to map items for the repository layer (consider adding a `map<R>()` method or constructing a new instance in the repo impl)

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3", "1.4", "1.5", "2.1"] },
    { "id": 1, "tasks": ["2.2", "2.3", "4.1", "4.2"] },
    { "id": 2, "tasks": ["5.1", "5.2", "8.1", "8.2"] },
    { "id": 3, "tasks": ["5.3", "5.4", "8.3", "8.4"] },
    { "id": 4, "tasks": ["6.1", "6.2"] },
    { "id": 5, "tasks": ["9.1", "9.2"] },
    { "id": 6, "tasks": ["11.1", "12.1"] },
    { "id": 7, "tasks": ["14.1"] },
    { "id": 8, "tasks": ["14.2", "14.3", "14.4", "14.5"] }
  ]
}
```
