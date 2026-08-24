# Implementation Plan: Devices and Sensors Management

## Overview

Implement full device and sensor management following Clean Architecture: domain entities/enums → repository contracts → DTOs → datasource contracts + backend implementations → repository implementations → Riverpod provider wiring → UI pages. All HTTP calls use the existing `authenticatedDioProvider` with standard error handling (404→NotFoundFailure, 422→ValidationFailure, DioException→NetworkFailure).

## Tasks

- [ ] 1. Create domain layer entities and enums
  - [ ] 1.1 Create DeviceType enum
    - Create `lib/domain/entities/device_type.dart`
    - Define enum with values: `sensor`, `camera`, `irrigation`
    - Add `static DeviceType fromString(String value)` factory that maps backend strings to enum values (defaults to `sensor` on unknown)
    - _Requirements: 1.2, 1.3_

  - [ ] 1.2 Create MetricType enum
    - Create `lib/domain/entities/metric_type.dart`
    - Define enum with values: `soilMoisture`, `airHumidity`, `temperature`, `uvIndex`
    - Add `static MetricType fromString(String value)` that maps snake_case backend strings (`soil_moisture`, `air_humidity`, `temperature`, `uv_index`) to enum values (defaults to `temperature` on unknown)
    - Add `String toBackendString()` that converts enum to snake_case backend format
    - Add `String get label` getter returning Spanish UI labels: "Humedad de suelo", "Humedad ambiental", "Temperatura", "Índice UV"
    - _Requirements: 2.2, 2.3_

  - [ ] 1.3 Create Device entity
    - Create `lib/domain/entities/device.dart`
    - Import `device_type.dart`
    - Define immutable class with fields: `id` (String), `name` (String), `type` (DeviceType), `isActive` (bool), `createdAt` (DateTime)
    - Use `const` constructor with all required named parameters
    - _Requirements: 1.1, 1.3_

  - [ ] 1.4 Create Sensor entity
    - Create `lib/domain/entities/sensor.dart`
    - Import `metric_type.dart`
    - Define immutable class with fields: `id` (String), `deviceId` (String), `name` (String), `metric` (MetricType), `unit` (String), `minOk` (double?), `maxOk` (double?), `isActive` (bool), `createdAt` (DateTime)
    - Use `const` constructor with required fields and optional `minOk`/`maxOk`
    - _Requirements: 2.1, 2.3_

  - [ ] 1.5 Create DeviceRepository contract
    - Create `lib/domain/repositories/device_repository.dart`
    - Import Device entity and DeviceType enum
    - Define `typedef DeviceRegistration = ({Device device, String apiKey})`
    - Define `abstract class DeviceRepository` with methods: `Future<List<Device>> getAll()`, `Future<DeviceRegistration> register(String name, DeviceType type)`, `Future<Device> revoke(String deviceId)`
    - _Requirements: 3.1, 3.2, 3.3_

  - [ ] 1.6 Create SensorManagementRepository contract
    - Create `lib/domain/repositories/sensor_management_repository.dart`
    - Import Sensor entity and MetricType enum
    - Define `abstract class SensorManagementRepository` with methods: `Future<List<Sensor>> getAll()`, `Future<List<Sensor>> getByDevice(String deviceId)`, `Future<Sensor> create({required String deviceId, required String name, required MetricType metric, double? minOk, double? maxOk})`, `Future<Sensor> update({required String sensorId, String? name, double? minOk, double? maxOk, bool? isActive})`
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 2. Create infrastructure DTOs
  - [ ] 2.1 Create DeviceDto
    - Create `lib/infrastructure/models/device_dto.dart`
    - Import Device entity and DeviceType enum
    - Define class with fields: `id`, `name`, `type` (String), `isActive`, `createdAt` (String)
    - Implement `factory DeviceDto.fromJson(Map<String, dynamic> json)` mapping backend keys: `id`, `name`, `type`, `is_active`, `created_at`
    - Implement `Device toEntity()` that converts type string via `DeviceType.fromString()` and parses `createdAt` via `DateTime.parse()`
    - _Requirements: 5.1, 5.2, 5.3_

  - [ ] 2.2 Create SensorDto
    - Create `lib/infrastructure/models/sensor_dto.dart`
    - Import Sensor entity and MetricType enum
    - Define class with fields: `id`, `deviceId`, `name`, `metric`, `unit` (String), `minOk` (double?), `maxOk` (double?), `isActive` (bool), `createdAt` (String)
    - Implement `factory SensorDto.fromJson(Map<String, dynamic> json)` mapping backend keys: `id`, `device_id`, `name`, `metric`, `unit`, `min_ok`, `max_ok`, `is_active`, `created_at`
    - Implement `Map<String, dynamic> toJson()` for serialization
    - Implement `Sensor toEntity()` that converts metric string via `MetricType.fromString()` and parses `createdAt`
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 3. Checkpoint - Domain and DTO validation
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 4. Create datasource contracts and backend implementations
  - [ ] 4.1 Create DeviceRemoteDataSource contract
    - Create `lib/infrastructure/datasources/device/device_remote_datasource.dart`
    - Import DeviceDto
    - Define `abstract class DeviceRemoteDataSource` with methods: `Future<List<DeviceDto>> fetchAll()`, `Future<Map<String, dynamic>> register(String name, String type)`, `Future<DeviceDto> revoke(String deviceId)`
    - _Requirements: 7.1, 7.2, 7.3_

  - [ ] 4.2 Create DeviceRemoteDataSourceBackend implementation
    - Create `lib/infrastructure/datasources/device/device_remote_datasource_backend.dart`
    - Import Dio, AppFailure types, DeviceDto, and the contract
    - Constructor receives `Dio` instance
    - `fetchAll()`: GET `/devices`, parse response list into `List<DeviceDto>`, catch DioException → throw NetworkFailure
    - `register()`: POST `/devices/register` with body `{name, type}`, return response data as Map, handle 422 → ValidationFailure
    - `revoke()`: PATCH `/devices/{deviceId}/revoke`, parse response into DeviceDto, handle 404 → NotFoundFailure
    - _Requirements: 7.4, 7.5, 7.6, 7.7, 16.1, 16.3_

  - [ ] 4.3 Create SensorRemoteManagementDataSource contract
    - Create `lib/infrastructure/datasources/sensor/sensor_remote_management_datasource.dart`
    - Import SensorDto
    - Define `abstract class SensorRemoteManagementDataSource` with methods: `Future<List<SensorDto>> fetchAll()`, `Future<List<SensorDto>> fetchByDevice(String deviceId)`, `Future<SensorDto> create({required String deviceId, required String name, required String metric, double? minOk, double? maxOk})`, `Future<SensorDto> update(String sensorId, Map<String, dynamic> fields)`
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

  - [ ] 4.4 Create SensorRemoteManagementDataSourceBackend implementation
    - Create `lib/infrastructure/datasources/sensor/sensor_remote_management_datasource_backend.dart`
    - Import Dio, AppFailure types, SensorDto, and the contract
    - Constructor receives `Dio` instance
    - `fetchAll()`: GET `/sensors`, parse list into `List<SensorDto>`, catch DioException → NetworkFailure
    - `fetchByDevice()`: GET `/devices/{deviceId}/sensors`, handle 404 → NotFoundFailure
    - `create()`: POST `/devices/{deviceId}/sensors` with body containing `name`, `metric`, and optional `min_ok`/`max_ok` (only if non-null), handle 422 → ValidationFailure
    - `update()`: PATCH `/sensors/{sensorId}` with only non-null fields, handle 404 → NotFoundFailure, 422 → ValidationFailure
    - _Requirements: 8.5, 8.6, 8.7, 8.8, 8.9, 8.10, 16.1, 16.2, 16.3_

- [ ] 5. Create repository implementations
  - [ ] 5.1 Create DeviceRepositoryImpl
    - Create `lib/infrastructure/repositories/device_repository_impl.dart`
    - Import DeviceRepository contract, DeviceRemoteDataSource, Device entity, DeviceType, DeviceDto
    - Constructor receives `DeviceRemoteDataSource`
    - `getAll()`: delegates to datasource `fetchAll()`, maps each DTO via `toEntity()`
    - `register()`: delegates to datasource `register()`, constructs Device from raw map + extracts `api_key`, returns `DeviceRegistration` record
    - `revoke()`: delegates to datasource `revoke()`, maps DTO via `toEntity()`
    - _Requirements: 9.1_

  - [ ] 5.2 Create SensorManagementRepositoryImpl
    - Create `lib/infrastructure/repositories/sensor_management_repository_impl.dart`
    - Import SensorManagementRepository contract, SensorRemoteManagementDataSource, Sensor entity, MetricType
    - Constructor receives `SensorRemoteManagementDataSource`
    - `getAll()`: delegates to `fetchAll()`, maps DTOs
    - `getByDevice()`: delegates to `fetchByDevice()`, maps DTOs
    - `create()`: converts MetricType to backend string via `toBackendString()`, delegates to datasource `create()`, maps DTO
    - `update()`: builds fields map from non-null parameters, delegates to datasource `update()`, maps DTO
    - _Requirements: 9.2_

- [ ] 6. Checkpoint - Infrastructure layer validation
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Create Riverpod provider wiring
  - [ ] 7.1 Create device providers
    - Create `lib/presentation/providers/device/device_providers.dart`
    - Import Riverpod, domain entities/repos, infrastructure datasource + backend impl, `authenticatedDioProvider`, repository impl
    - Define `deviceDataSourceProvider`: Provider that creates `DeviceRemoteDataSourceBackend` using `ref.watch(authenticatedDioProvider)`
    - Define `deviceRepositoryProvider`: Provider that creates `DeviceRepositoryImpl` with `ref.watch(deviceDataSourceProvider)`
    - Define `devicesControllerProvider`: AsyncNotifierProvider<DevicesController, List<Device>>
    - Implement `DevicesController extends AsyncNotifier<List<Device>>` with `build()` that calls `getAll()`, `registerDevice(name, type)` that calls register + `ref.invalidateSelf()` + returns DeviceRegistration, `revokeDevice(deviceId)` that calls revoke + `ref.invalidateSelf()`
    - _Requirements: 9.3, 9.5_

  - [ ] 7.2 Create sensor management providers
    - Create `lib/presentation/providers/sensor/sensor_management_providers.dart`
    - Import Riverpod, domain entities/repos, infrastructure datasource + backend impl, `authenticatedDioProvider`, repository impl
    - Define `sensorManagementDataSourceProvider`: Provider that creates `SensorRemoteManagementDataSourceBackend` using `ref.watch(authenticatedDioProvider)`
    - Define `sensorManagementRepositoryProvider`: Provider that creates `SensorManagementRepositoryImpl` with `ref.watch(sensorManagementDataSourceProvider)`
    - Define `sensorsControllerProvider`: AsyncNotifierProvider<SensorsController, List<Sensor>>
    - Implement `SensorsController extends AsyncNotifier<List<Sensor>>` with `build()` that calls `getAll()`, `createSensor(...)` that calls create + `ref.invalidateSelf()`, `updateSensor(...)` that calls update + `ref.invalidateSelf()`
    - _Requirements: 9.4, 9.5_

- [ ] 8. Implement Devices Page UI
  - [ ] 8.1 Rewrite DevicesPage with full device management
    - Rewrite `lib/presentation/pages/devices/devices_page.dart` replacing the placeholder
    - Use `ConsumerWidget` watching `devicesControllerProvider`
    - Render device list using `AsyncValue.when()` for loading/error/data states
    - Each device tile/card shows: name (title), type icon, status Chip (Activo/green vs Revocado/grey), creation date
    - Active devices show a "Revocar" action button; disabled for inactive devices
    - Loading state: `CircularProgressIndicator`
    - Error state: error message with a retry button that calls `ref.invalidate(devicesControllerProvider)`
    - Add FAB "Registrar dispositivo" that opens a registration dialog
    - Registration dialog: form with TextField for name (validated ≥1 char) + DropdownButtonFormField for DeviceType
    - On successful registration: show API key dialog with monospace text, "Copiar" button (Clipboard.setData), warning "Esta clave solo se muestra una vez"
    - On dismiss of API key dialog: list refreshes automatically via `invalidateSelf()`
    - Revoke flow: confirmation AlertDialog with warning text → calls `revokeDevice(id)` → list refreshes
    - Show SnackBar on operation failure
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 12.1, 12.2, 12.3, 12.4, 12.5, 16.4_

- [ ] 9. Implement Sensors Page UI
  - [ ] 9.1 Rewrite SensorsPage with full sensor management
    - Rewrite `lib/presentation/pages/sensors/sensors_page.dart` replacing the placeholder
    - Use `ConsumerWidget` watching both `sensorsControllerProvider` and `devicesControllerProvider`
    - Map `deviceId → device.name` from the devices list for display
    - Render sensor list using `AsyncValue.when()` for loading/error/data states
    - Each sensor row/card shows: name, metric label (via `MetricType.label`), unit, min_ok/max_ok (or "—" if null), device name, status
    - Loading state: `CircularProgressIndicator`
    - Error state: error message with retry button
    - Add FAB "Crear sensor" that opens a creation dialog
    - Create dialog: DropdownButtonFormField for device (active devices only), TextField for name (validated 1–255 chars), DropdownButtonFormField for MetricType, optional TextFormFields for min_ok and max_ok
    - On successful creation: list refreshes via `invalidateSelf()`
    - Each sensor has an "Editar" action → opens edit dialog
    - Edit dialog: prepopulated TextField for name, TextFormFields for min_ok/max_ok (clearable to null)
    - On submit: sends only changed fields via `updateSensor()`
    - Show SnackBar on operation failure
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 14.1, 14.2, 14.3, 14.4, 14.5, 15.1, 15.2, 15.3, 15.4, 15.5, 16.4_

- [ ] 10. Final checkpoint - Full feature validation
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation between architectural layers
- The design has no Correctness Properties section, so no property-based tests are included
- All HTTP calls use `authenticatedDioProvider` (already existing) — no new Dio instances needed
- Error handling follows existing patterns in `app_failure.dart`: NotFoundFailure, ValidationFailure, NetworkFailure
- Controllers use `ref.invalidateSelf()` after mutations to re-fetch the list automatically
- SensorsPage watches both sensors and devices providers to resolve deviceId → device name

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["1.3", "1.4"] },
    { "id": 2, "tasks": ["1.5", "1.6"] },
    { "id": 3, "tasks": ["2.1", "2.2"] },
    { "id": 4, "tasks": ["4.1", "4.3"] },
    { "id": 5, "tasks": ["4.2", "4.4"] },
    { "id": 6, "tasks": ["5.1", "5.2"] },
    { "id": 7, "tasks": ["7.1", "7.2"] },
    { "id": 8, "tasks": ["8.1", "9.1"] }
  ]
}
```
