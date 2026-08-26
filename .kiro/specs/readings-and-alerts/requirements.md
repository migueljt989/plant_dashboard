# Requirements Document

## Introduction

Feature de historial de lecturas y alertas para el panel IoT de jitomates cherry. Implementa la capa de infraestructura (entidades, DTOs, datasources, repositorios) y las páginas de UI para consultar lecturas paginadas con filtros (`/lecturas`) y alertas paginadas con filtros (`/alertas`). Usa endpoints REST existentes del backend con autenticación Bearer, separando esta funcionalidad del `SensorRepository` existente (usado para streaming en tiempo real del dashboard).

## Glossary

- **Reading**: Registro individual de una medición de un sensor en un momento dado, conteniendo valor, unidad, métrica y timestamp.
- **Alert**: Notificación generada por el backend cuando el valor de un sensor cruza un umbral configurado (breach) o regresa al rango normal (recovery).
- **ReadingsRepository**: Repositorio abstracto responsable de consultar lecturas paginadas y la lectura más reciente desde el backend REST. Separado del `SensorRepository` existente.
- **AlertsRepository**: Repositorio abstracto responsable de consultar alertas paginadas desde el backend REST.
- **ReadingsDataSource**: Contrato abstracto del datasource que comunica con los endpoints `/readings` y `/readings/latest` del backend.
- **AlertsDataSource**: Contrato abstracto del datasource que comunica con el endpoint `/alerts` del backend.
- **PaginatedResponse**: Estructura genérica que encapsula una lista de items junto con metadatos de paginación (total, limit, offset).
- **ReadingsPage**: Página de UI en la ruta `/lecturas` que muestra lecturas históricas paginadas con filtros.
- **AlertsPage**: Página de UI en la ruta `/alertas` que muestra alertas paginadas con filtros y distinción visual por tipo.
- **MetricType**: Enum ya existente (`soil_moisture`, `air_humidity`, `temperature`, `uv_index`) reutilizado de la feature devices-and-sensors.
- **AlertType**: Tipo de alerta: `breach` (valor fuera de rango) o `recovery` (valor regresó al rango).
- **BreachedBound**: Indica cuál umbral fue violado: `min_ok` o `max_ok`.
- **DeliveryStatus**: Estado de entrega de la notificación de alerta: `pending`, `sent`, `failed`, `skipped`.
- **ReadingsFilter**: Conjunto de parámetros opcionales para filtrar lecturas: sensor_id, device_id, metric, from, to.
- **AlertsFilter**: Conjunto de parámetros opcionales para filtrar alertas: sensor_id, device_id, metric, alert_type, from, to.

## Requirements

### Requirement 1: Reading Entity and DTO

**User Story:** As a developer, I want a domain entity and DTO that model the full reading response from the backend, so that the readings feature has a proper domain representation separate from the existing simplified `SensorReading`.

#### Acceptance Criteria

1. THE Reading entity SHALL contain the fields: id (String), sensorId (String), sensorName (String), deviceId (String), metric (MetricType), unit (String), value (double), and recordedAt (DateTime).
2. THE ReadingDto SHALL parse a JSON object matching the `ReadingResponseSchema` into a ReadingDto instance.
3. THE ReadingDto SHALL convert to a Reading domain entity via a `toEntity()` method.
4. FOR ALL valid ReadingDto instances, converting to entity and back to JSON SHALL preserve all field values (round-trip property).

### Requirement 2: Alert Entity and DTO

**User Story:** As a developer, I want a domain entity and DTO that model the full alert response from the backend, so that alerts can be displayed with all relevant context.

#### Acceptance Criteria

1. THE Alert entity SHALL contain the fields: id (String), sensorId (String), sensorName (String), deviceId (String), metric (MetricType), unit (String), alertType (AlertType), value (double), breachedBound (BreachedBound nullable), minOk (double nullable), maxOk (double nullable), triggeredAt (DateTime), and deliveryStatus (DeliveryStatus).
2. THE AlertDto SHALL parse a JSON object matching the `AlertResponseSchema` into an AlertDto instance.
3. THE AlertDto SHALL convert to an Alert domain entity via a `toEntity()` method.
4. FOR ALL valid AlertDto instances, converting to entity and back to JSON SHALL preserve all field values (round-trip property).

### Requirement 3: Supporting Enums

**User Story:** As a developer, I want enums for AlertType, BreachedBound, and DeliveryStatus, so that domain entities use type-safe values instead of raw strings.

#### Acceptance Criteria

1. THE AlertType enum SHALL define values `breach` and `recovery` with conversion methods to and from backend snake_case strings.
2. THE BreachedBound enum SHALL define values `minOk` and `maxOk` with conversion methods to and from backend snake_case strings (`min_ok`, `max_ok`).
3. THE DeliveryStatus enum SHALL define values `pending`, `sent`, `failed`, and `skipped` with conversion methods to and from backend strings.

### Requirement 4: Paginated Response Model

**User Story:** As a developer, I want a generic paginated response structure, so that both readings and alerts can reuse the same pagination logic.

#### Acceptance Criteria

1. THE PaginatedResponse model SHALL be generic over the item type and contain fields: items (List of T), total (int), limit (int), and offset (int).
2. WHEN the backend returns a response with `items` and `pagination` fields, THE PaginatedResponse factory SHALL correctly parse both sections.
3. THE PaginatedResponse SHALL expose a computed `hasMore` property that returns true WHEN `offset + items.length < total`.

### Requirement 5: Readings DataSource Contract and Backend Implementation

**User Story:** As a developer, I want an abstract datasource contract and a REST implementation for readings, so that the readings data layer is decoupled from the HTTP client.

#### Acceptance Criteria

1. THE ReadingsDataSource contract SHALL define a method `fetchReadings` that accepts optional filters (sensorId, deviceId, metric, from, to) and pagination params (limit, offset) and returns a PaginatedResponse of ReadingDto.
2. THE ReadingsDataSource contract SHALL define a method `fetchLatestReading` that accepts optional filters (sensorId, deviceId, metric) and returns a single ReadingDto.
3. WHEN `fetchReadings` is called, THE ReadingsDataSourceBackend implementation SHALL send a GET request to `/readings` with the provided query parameters using the authenticated Dio instance.
4. WHEN `fetchLatestReading` is called, THE ReadingsDataSourceBackend implementation SHALL send a GET request to `/readings/latest` with the provided query parameters using the authenticated Dio instance.
5. IF the backend responds with a 404 status, THEN THE ReadingsDataSourceBackend SHALL throw a NotFoundFailure.
6. IF the backend responds with a network error, THEN THE ReadingsDataSourceBackend SHALL throw a NetworkFailure.

### Requirement 6: Alerts DataSource Contract and Backend Implementation

**User Story:** As a developer, I want an abstract datasource contract and a REST implementation for alerts, so that the alerts data layer is decoupled from the HTTP client.

#### Acceptance Criteria

1. THE AlertsDataSource contract SHALL define a method `fetchAlerts` that accepts optional filters (sensorId, deviceId, metric, alertType, from, to) and pagination params (limit, offset) and returns a PaginatedResponse of AlertDto.
2. WHEN `fetchAlerts` is called, THE AlertsDataSourceBackend implementation SHALL send a GET request to `/alerts` with the provided query parameters using the authenticated Dio instance.
3. IF the backend responds with a network error, THEN THE AlertsDataSourceBackend SHALL throw a NetworkFailure.

### Requirement 7: Readings Repository

**User Story:** As a developer, I want an abstract ReadingsRepository and its implementation, so that the presentation layer can fetch paginated readings and the latest reading without knowing about HTTP details.

#### Acceptance Criteria

1. THE ReadingsRepository contract SHALL define a method `getReadings` that accepts optional filters (sensorId, deviceId, metric, from, to) and pagination params (limit, offset) and returns a PaginatedResponse of Reading entities.
2. THE ReadingsRepository contract SHALL define a method `getLatestReading` that accepts optional filters (sensorId, deviceId, metric) and returns a Reading entity.
3. WHEN `getReadings` is called, THE ReadingsRepositoryImpl SHALL delegate to the ReadingsDataSource and map each ReadingDto to a Reading entity.
4. WHEN `getLatestReading` is called, THE ReadingsRepositoryImpl SHALL delegate to the ReadingsDataSource and map the ReadingDto to a Reading entity.

### Requirement 8: Alerts Repository

**User Story:** As a developer, I want an abstract AlertsRepository and its implementation, so that the presentation layer can fetch paginated alerts without knowing about HTTP details.

#### Acceptance Criteria

1. THE AlertsRepository contract SHALL define a method `getAlerts` that accepts optional filters (sensorId, deviceId, metric, alertType, from, to) and pagination params (limit, offset) and returns a PaginatedResponse of Alert entities.
2. WHEN `getAlerts` is called, THE AlertsRepositoryImpl SHALL delegate to the AlertsDataSource and map each AlertDto to an Alert entity.

### Requirement 9: Readings Page with Filters

**User Story:** As a user, I want to see a paginated list of sensor readings with filters, so that I can review historical data for specific sensors, devices, metrics, or time periods.

#### Acceptance Criteria

1. WHEN the user navigates to `/lecturas`, THE ReadingsPage SHALL display a list of readings in tabular format with columns: sensor name, metric, value with unit, and recorded_at timestamp.
2. THE ReadingsPage SHALL display filter controls at the top for: device selection, sensor selection, metric selection, and date range (from/to).
3. WHEN the user applies a filter, THE ReadingsPage SHALL reload the readings list from offset 0 using the selected filter values.
4. WHEN the user changes the date range filter, THE ReadingsPage SHALL use the selected from and to dates as query parameters.
5. WHILE readings are loading, THE ReadingsPage SHALL display a loading indicator.
6. IF the readings request fails, THEN THE ReadingsPage SHALL display an error message with a retry option.
7. THE ReadingsPage SHALL support pagination via a "load more" button or page navigation controls at the bottom of the list.
8. WHEN more readings are available beyond the current page, THE ReadingsPage SHALL enable the pagination control to fetch the next batch.

### Requirement 10: Latest Reading Display

**User Story:** As a user, I want to see the latest reading at the top of the readings page, so that I can quickly check the most recent sensor value without scrolling through history.

#### Acceptance Criteria

1. THE ReadingsPage SHALL display a summary card at the top showing the latest reading (sensor name, metric, value with unit, and timestamp).
2. WHEN a filter is applied, THE latest reading card SHALL update to reflect the latest reading matching the current filters.
3. WHILE the latest reading is loading, THE summary card SHALL display a loading placeholder.
4. IF no reading matches the current filters, THEN THE summary card SHALL display a "no data" message.

### Requirement 11: Alerts Page with Filters

**User Story:** As a user, I want to see a paginated list of alerts with filters, so that I can review when sensor thresholds were breached or recovered.

#### Acceptance Criteria

1. WHEN the user navigates to `/alertas`, THE AlertsPage SHALL display a list of alerts showing: sensor name, metric, alert type, value with unit, breached bound, and triggered_at timestamp.
2. THE AlertsPage SHALL display filter controls at the top for: device selection, sensor selection, metric selection, alert type selection, and date range (from/to).
3. WHEN the user applies a filter, THE AlertsPage SHALL reload the alerts list from offset 0 using the selected filter values.
4. THE AlertsPage SHALL visually distinguish breach alerts (warning/red styling) from recovery alerts (success/green styling).
5. WHEN an alert has a breached_bound value, THE AlertsPage SHALL display which bound was violated (min or max) alongside the configured threshold values (min_ok, max_ok).
6. WHILE alerts are loading, THE AlertsPage SHALL display a loading indicator.
7. IF the alerts request fails, THEN THE AlertsPage SHALL display an error message with a retry option.
8. THE AlertsPage SHALL support pagination via a "load more" button or page navigation controls at the bottom of the list.
9. WHEN more alerts are available beyond the current page, THE AlertsPage SHALL enable the pagination control to fetch the next batch.

### Requirement 12: Riverpod Providers for Readings

**User Story:** As a developer, I want Riverpod providers that wire the readings infrastructure and expose state to the UI, so that the ReadingsPage can consume data reactively.

#### Acceptance Criteria

1. THE readingsDataSourceProvider SHALL provide a ReadingsDataSourceBackend instance using the authenticatedDioProvider.
2. THE readingsRepositoryProvider SHALL provide a ReadingsRepositoryImpl instance using the readingsDataSourceProvider.
3. THE readingsControllerProvider SHALL manage the paginated readings state (loading, data, error) and expose methods to apply filters and load more pages.
4. THE latestReadingProvider SHALL expose an AsyncValue of the latest reading, accepting the current filter parameters.

### Requirement 13: Riverpod Providers for Alerts

**User Story:** As a developer, I want Riverpod providers that wire the alerts infrastructure and expose state to the UI, so that the AlertsPage can consume data reactively.

#### Acceptance Criteria

1. THE alertsDataSourceProvider SHALL provide an AlertsDataSourceBackend instance using the authenticatedDioProvider.
2. THE alertsRepositoryProvider SHALL provide an AlertsRepositoryImpl instance using the alertsDataSourceProvider.
3. THE alertsControllerProvider SHALL manage the paginated alerts state (loading, data, error) and expose methods to apply filters and load more pages.
