# Requirements Document

## Introduction

Full devices and sensors management feature for the Flutter Web plant IoT dashboard. This feature provides the infrastructure layer (entities, DTOs, datasource contracts with backend implementations, repositories) and the UI for managing IoT devices and their associated sensors. Users can list, register, and revoke devices at the /dispositivos route, and list, create, and edit sensors (including threshold configuration) at the /sensores route. All operations communicate with the FastAPI backend via the existing authenticated Dio instance.

## Glossary

- **Device**: A physical IoT unit (sensor node, camera, or irrigation controller) registered in the backend, identified by a UUID.
- **Sensor**: A logical measurement endpoint attached to a Device, identified by a UUID, that reports a specific metric type.
- **Device_Repository**: Domain-layer abstract contract exposing device management operations (list, register, revoke) to the presentation layer.
- **Sensor_Repository_Management**: Domain-layer abstract contract exposing sensor metadata operations (list all, list by device, create, update) to the presentation layer. Distinct from the existing SensorRepository which handles readings.
- **Device_Remote_DataSource**: Infrastructure-layer abstract contract for device-related HTTP calls to the backend API.
- **Sensor_Remote_Management_DataSource**: Infrastructure-layer abstract contract for sensor metadata HTTP calls to the backend API.
- **DeviceDto**: Infrastructure-layer DTO mapping backend device JSON responses to the Device entity.
- **SensorDto**: Infrastructure-layer DTO mapping backend sensor JSON responses to the Sensor entity.
- **DeviceType**: Domain enum with values sensor, camera, and irrigation representing the hardware category of a device.
- **MetricType**: Domain enum with values soil_moisture, air_humidity, temperature, and uv_index representing the physical quantity a sensor measures.
- **API_Key**: A secret string returned exclusively at device registration time, used by the physical device to authenticate its data submissions to the backend.
- **Threshold**: A pair of optional numeric bounds (min_ok, max_ok) on a sensor that define the acceptable range for alerting purposes.

## Requirements

### Requirement 1: Device Entity and DeviceType Enum

**User Story:** As a developer, I want a Device domain entity and a DeviceType enum, so that the domain layer has a typed representation of IoT devices independent of any backend implementation.

#### Acceptance Criteria

1. THE Device entity SHALL contain the fields: id (String), name (String), type (DeviceType), isActive (bool), and createdAt (DateTime).
2. THE DeviceType enum SHALL define exactly three values: sensor, camera, and irrigation.
3. THE Device entity SHALL reside in the domain/entities directory and have no dependency on infrastructure or presentation packages.

### Requirement 2: Sensor Entity and MetricType Enum

**User Story:** As a developer, I want a Sensor domain entity and a MetricType enum, so that the domain layer has a typed representation of sensor metadata independent of any backend implementation.

#### Acceptance Criteria

1. THE Sensor entity SHALL contain the fields: id (String), deviceId (String), name (String), metric (MetricType), unit (String), minOk (double nullable), maxOk (double nullable), isActive (bool), and createdAt (DateTime).
2. THE MetricType enum SHALL define exactly four values: soilMoisture, airHumidity, temperature, and uvIndex.
3. THE Sensor entity SHALL reside in the domain/entities directory and have no dependency on infrastructure or presentation packages.

### Requirement 3: Device Repository Contract

**User Story:** As a developer, I want an abstract Device_Repository in the domain layer, so that the presentation layer can manage devices without knowing how the data is fetched or persisted.

#### Acceptance Criteria

1. THE Device_Repository SHALL expose a method to list all devices returning a Future of List of Device.
2. THE Device_Repository SHALL expose a method to register a device accepting a name (String) and type (DeviceType), returning a Future of a record containing the Device and its API_Key (String).
3. THE Device_Repository SHALL expose a method to revoke a device accepting a device ID (String), returning a Future of Device with updated isActive status.

### Requirement 4: Sensor Management Repository Contract

**User Story:** As a developer, I want an abstract Sensor_Repository_Management in the domain layer, so that the presentation layer can manage sensor metadata without knowing how the data is fetched or persisted.

#### Acceptance Criteria

1. THE Sensor_Repository_Management SHALL expose a method to list all sensors across all devices returning a Future of List of Sensor.
2. THE Sensor_Repository_Management SHALL expose a method to list sensors for a specific device accepting a device ID (String), returning a Future of List of Sensor.
3. THE Sensor_Repository_Management SHALL expose a method to create a sensor accepting a device ID (String), name (String), metric (MetricType), minOk (double nullable), and maxOk (double nullable), returning a Future of Sensor.
4. THE Sensor_Repository_Management SHALL expose a method to update a sensor accepting a sensor ID (String) and optional fields name (String nullable), minOk (double nullable), maxOk (double nullable), and isActive (bool nullable), returning a Future of Sensor.

### Requirement 5: Device DTO with JSON Mapping

**User Story:** As a developer, I want a DeviceDto that maps backend JSON to the Device entity, so that the infrastructure layer can serialize and deserialize device data correctly.

#### Acceptance Criteria

1. THE DeviceDto SHALL implement a fromJson factory that maps the backend fields id, name, type, is_active, and created_at to their corresponding Dart properties.
2. THE DeviceDto SHALL implement a toEntity method that converts the DTO into a Device domain entity, mapping the type string to the DeviceType enum.
3. THE DeviceDto SHALL reside in the infrastructure/models directory.

### Requirement 6: Sensor DTO with JSON Mapping

**User Story:** As a developer, I want a SensorDto that maps backend JSON to the Sensor entity, so that the infrastructure layer can serialize and deserialize sensor metadata correctly.

#### Acceptance Criteria

1. THE SensorDto SHALL implement a fromJson factory that maps the backend fields id, device_id, name, metric, unit, min_ok, max_ok, is_active, and created_at to their corresponding Dart properties.
2. THE SensorDto SHALL implement a toEntity method that converts the DTO into a Sensor domain entity, mapping the metric string to the MetricType enum.
3. THE SensorDto SHALL reside in the infrastructure/models directory.
4. FOR ALL valid Sensor objects, converting to JSON via toJson and then parsing back via fromJson SHALL produce an equivalent SensorDto (round-trip property).

### Requirement 7: Device Remote DataSource Contract and Backend Implementation

**User Story:** As a developer, I want a Device_Remote_DataSource contract and its backend implementation using the authenticated Dio instance, so that device HTTP operations are encapsulated and swappable.

#### Acceptance Criteria

1. THE Device_Remote_DataSource SHALL expose a method fetchAll that returns a Future of List of DeviceDto.
2. THE Device_Remote_DataSource SHALL expose a method register that accepts a name (String) and type (String), returning a Future of a Map containing the device data and the api_key field.
3. THE Device_Remote_DataSource SHALL expose a method revoke that accepts a device ID (String), returning a Future of DeviceDto.
4. WHEN fetchAll is called, THE backend implementation SHALL send a GET request to /devices using the authenticatedDioProvider instance.
5. WHEN register is called, THE backend implementation SHALL send a POST request to /devices/register with body containing name and type.
6. WHEN revoke is called with a device ID, THE backend implementation SHALL send a PATCH request to /devices/{device_id}/revoke.
7. IF the revoke endpoint returns a 404 status, THEN THE backend implementation SHALL throw a NotFoundFailure.

### Requirement 8: Sensor Remote Management DataSource Contract and Backend Implementation

**User Story:** As a developer, I want a Sensor_Remote_Management_DataSource contract and its backend implementation using the authenticated Dio instance, so that sensor metadata HTTP operations are encapsulated and swappable.

#### Acceptance Criteria

1. THE Sensor_Remote_Management_DataSource SHALL expose a method fetchAll that returns a Future of List of SensorDto.
2. THE Sensor_Remote_Management_DataSource SHALL expose a method fetchByDevice that accepts a device ID (String), returning a Future of List of SensorDto.
3. THE Sensor_Remote_Management_DataSource SHALL expose a method create that accepts a device ID (String), name (String), metric (String), minOk (double nullable), and maxOk (double nullable), returning a Future of SensorDto.
4. THE Sensor_Remote_Management_DataSource SHALL expose a method update that accepts a sensor ID (String) and a Map of optional fields, returning a Future of SensorDto.
5. WHEN fetchAll is called, THE backend implementation SHALL send a GET request to /sensors using the authenticatedDioProvider instance.
6. WHEN fetchByDevice is called, THE backend implementation SHALL send a GET request to /devices/{device_id}/sensors.
7. WHEN create is called, THE backend implementation SHALL send a POST request to /devices/{device_id}/sensors with body containing name, metric, min_ok, and max_ok.
8. WHEN update is called, THE backend implementation SHALL send a PATCH request to /sensors/{sensor_id} with only the non-null fields in the body.
9. IF any endpoint returns a 404 status, THEN THE backend implementation SHALL throw a NotFoundFailure.
10. IF any endpoint returns a 422 status, THEN THE backend implementation SHALL throw a ValidationFailure with the detail message from the response body.

### Requirement 9: Repository Implementations and Provider Wiring

**User Story:** As a developer, I want DeviceRepositoryImpl and SensorManagementRepositoryImpl that delegate to their respective datasources, and Riverpod providers that wire everything together, so that the presentation layer can access device and sensor operations through providers.

#### Acceptance Criteria

1. THE DeviceRepositoryImpl SHALL receive a Device_Remote_DataSource by constructor and delegate all operations to it, converting DTOs to domain entities.
2. THE SensorManagementRepositoryImpl SHALL receive a Sensor_Remote_Management_DataSource by constructor and delegate all operations to it, converting DTOs to domain entities.
3. THE provider wiring SHALL expose a deviceRepositoryProvider of type Provider of Device_Repository.
4. THE provider wiring SHALL expose a sensorManagementRepositoryProvider of type Provider of Sensor_Repository_Management.
5. THE datasource providers SHALL use the authenticatedDioProvider to construct the backend datasource implementations.

### Requirement 10: Devices Page — List Devices with Status and Associated Sensors

**User Story:** As a user, I want to see a list of all my registered IoT devices with their current active/inactive status and the ability to expand each device to see its associated sensors inline, so that I can quickly understand the topology of my sensor network.

#### Acceptance Criteria

1. WHEN the user navigates to /dispositivos, THE Devices_Page SHALL fetch and display the list of all registered devices.
2. THE Devices_Page SHALL display each device's name, type icon, active status, creation date, and a count of associated sensors in the subtitle.
3. WHILE the device list is loading, THE Devices_Page SHALL display a loading indicator.
4. IF the device list fetch fails, THEN THE Devices_Page SHALL display an error message with a retry option.
5. THE Devices_Page SHALL visually distinguish active devices from inactive (revoked) devices.
6. WHEN the user expands a device card, THE Devices_Page SHALL display the list of sensors associated with that device using a shared SensorTile widget.
7. IF a device has no associated sensors, THEN the expanded section SHALL display a "Sin sensores asignados" message.

### Requirement 11: Devices Page — Register New Device

**User Story:** As a user, I want to register a new IoT device by providing a name and selecting its type, so that the backend creates the device and provides me with an API key for hardware configuration.

#### Acceptance Criteria

1. WHEN the user triggers device registration, THE Devices_Page SHALL display a form requesting a device name and type selection (sensor, camera, or irrigation).
2. THE registration form SHALL validate that the device name contains at least 1 character before enabling submission.
3. WHEN the registration form is submitted, THE Devices_Page SHALL send the registration request to the backend via the Device_Repository.
4. WHEN the backend returns a successful registration containing the API_Key, THE Devices_Page SHALL display the API_Key prominently in a dialog with a copy-to-clipboard action and a warning that the key is shown only once.
5. WHEN the API_Key dialog is dismissed, THE Devices_Page SHALL refresh the device list to include the newly registered device.
6. IF the registration request fails, THEN THE Devices_Page SHALL display the error message to the user.

### Requirement 12: Devices Page — Revoke Device

**User Story:** As a user, I want to revoke an active device, so that its API key is invalidated and it can no longer submit data to the backend.

#### Acceptance Criteria

1. WHEN the user triggers revocation on an active device, THE Devices_Page SHALL display a confirmation dialog warning that the action is destructive and the device will no longer be able to send data.
2. WHEN the user confirms the revocation, THE Devices_Page SHALL send the revoke request to the backend via the Device_Repository.
3. WHEN the revocation succeeds, THE Devices_Page SHALL update the device's status to inactive in the displayed list without a full page reload.
4. IF the revocation request fails, THEN THE Devices_Page SHALL display the error message to the user.
5. THE Devices_Page SHALL disable the revoke action for devices that are already inactive.

### Requirement 13: Sensors Page — List All Sensors Grouped by Device

**User Story:** As a user, I want to see all my sensors visually grouped by the device they belong to, with a clear header for each device, so that I can understand the relationship between devices and sensors at a glance.

#### Acceptance Criteria

1. WHEN the user navigates to /sensores, THE Sensors_Page SHALL fetch and display the list of all sensors grouped by their parent device.
2. THE Sensors_Page SHALL display a device group header for each device showing the device name, type icon, and sensor count.
3. Within each device group, THE Sensors_Page SHALL display each sensor's name, metric type, unit, threshold values (min_ok and max_ok when set), and active status using a shared SensorTile widget.
4. WHILE the sensor list is loading, THE Sensors_Page SHALL display a loading indicator.
5. IF the sensor list fetch fails, THEN THE Sensors_Page SHALL display an error message with a retry option.
6. THE Sensors_Page SHALL derive the grouped structure from a sensorsByDeviceProvider that reorganizes the flat sensor list by deviceId without making additional backend calls.

### Requirement 14: Sensors Page — Create Sensor on a Device

**User Story:** As a user, I want to create a new sensor on a specific device by providing its name, metric type, and optional thresholds, so that the backend registers the sensor for data collection.

#### Acceptance Criteria

1. WHEN the user triggers sensor creation, THE Sensors_Page SHALL display a form requesting the target device (selectable from active devices), sensor name, metric type (soil_moisture, air_humidity, temperature, or uv_index), and optional threshold fields (min_ok and max_ok).
2. THE sensor creation form SHALL validate that the sensor name is between 1 and 255 characters.
3. WHEN the sensor creation form is submitted, THE Sensors_Page SHALL send the creation request to the backend via the Sensor_Repository_Management.
4. WHEN the creation succeeds, THE Sensors_Page SHALL refresh the sensor list to include the newly created sensor.
5. IF the creation request fails, THEN THE Sensors_Page SHALL display the error message to the user.

### Requirement 15: Sensors Page — Edit Sensor Thresholds

**User Story:** As a user, I want to edit a sensor's thresholds (min_ok and max_ok) and optionally its name, so that I can tune the acceptable value range for alerting without recreating the sensor.

#### Acceptance Criteria

1. WHEN the user triggers editing on a sensor, THE Sensors_Page SHALL display a form pre-populated with the sensor's current name, min_ok, and max_ok values.
2. THE edit form SHALL allow min_ok and max_ok to be set to null (cleared) to indicate no threshold.
3. WHEN the edit form is submitted, THE Sensors_Page SHALL send only the changed fields to the backend via the Sensor_Repository_Management update method.
4. WHEN the update succeeds, THE Sensors_Page SHALL reflect the updated values in the displayed sensor list without a full page reload.
5. IF the update request fails, THEN THE Sensors_Page SHALL display the error message to the user.

### Requirement 16: Error Handling for Device and Sensor Operations

**User Story:** As a user, I want clear error feedback when device or sensor operations fail, so that I understand what went wrong and can take corrective action.

#### Acceptance Criteria

1. WHEN any device or sensor API call returns a 404 status, THE corresponding datasource SHALL throw a NotFoundFailure with a descriptive message.
2. WHEN any device or sensor API call returns a 422 status, THE corresponding datasource SHALL throw a ValidationFailure with the detail message from the response body.
3. IF an unexpected network error occurs during any device or sensor operation, THEN THE corresponding datasource SHALL throw a NetworkFailure with the underlying error message.
4. WHEN a failure is thrown, THE presentation layer controller SHALL expose the failure message through the AsyncValue error state for the UI to render.
