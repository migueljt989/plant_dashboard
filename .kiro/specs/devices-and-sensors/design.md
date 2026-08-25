# Technical Design: Devices and Sensors Management

## Overview

This design adds full device and sensor management to the plant IoT dashboard. It follows the established Clean Architecture pattern: domain entities + enums → abstract repository contracts → DTOs with JSON mapping → datasource contracts + backend implementations → Riverpod provider wiring → presentation controllers + UI pages.

All authenticated HTTP calls use the existing `authenticatedDioProvider` (which includes the TokenInterceptor for automatic token refresh).

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION                                 │
│                                                                       │
│  DevicesController (AsyncNotifier)   SensorsController (AsyncNotifier)│
│       ↓ ref.read                            ↓ ref.read               │
│  deviceRepositoryProvider          sensorManagementRepositoryProvider │
└──────────────────┬──────────────────────────────┬────────────────────┘
                   │                              │
┌──────────────────▼──────────────────────────────▼────────────────────┐
│                         INFRASTRUCTURE                                │
│                                                                       │
│  DeviceRepositoryImpl                SensorManagementRepositoryImpl   │
│    └── DeviceRemoteDataSource          └── SensorRemoteManagementDS   │
│          └── ...BackendImpl (Dio)            └── ...BackendImpl (Dio) │
│                    ↓                                  ↓               │
│              authenticatedDioProvider                                  │
│                    ↓                                                  │
│              TokenInterceptor (auto Bearer + refresh)                 │
└──────────────────────────────────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────────────┐
│                           DOMAIN                                     │
│                                                                       │
│  Device entity    Sensor entity    DeviceType enum    MetricType enum │
│  DeviceRepository (abstract)       SensorManagementRepository (abs)  │
└──────────────────────────────────────────────────────────────────────┘
```

## Component Design

### 1. Domain Layer

#### DeviceType Enum

```dart
// lib/domain/entities/device_type.dart
enum DeviceType {
  sensor,
  camera,
  irrigation;

  /// Maps the backend string representation to the enum.
  static DeviceType fromString(String value) {
    return DeviceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeviceType.sensor,
    );
  }
}
```

#### MetricType Enum

```dart
// lib/domain/entities/metric_type.dart
enum MetricType {
  soilMoisture,
  airHumidity,
  temperature,
  uvIndex;

  /// Backend uses snake_case strings.
  static MetricType fromString(String value) {
    switch (value) {
      case 'soil_moisture': return MetricType.soilMoisture;
      case 'air_humidity': return MetricType.airHumidity;
      case 'temperature': return MetricType.temperature;
      case 'uv_index': return MetricType.uvIndex;
      default: return MetricType.temperature;
    }
  }

  /// Converts to the backend snake_case format.
  String toBackendString() {
    switch (this) {
      case MetricType.soilMoisture: return 'soil_moisture';
      case MetricType.airHumidity: return 'air_humidity';
      case MetricType.temperature: return 'temperature';
      case MetricType.uvIndex: return 'uv_index';
    }
  }

  /// Human-readable label for UI.
  String get label {
    switch (this) {
      case MetricType.soilMoisture: return 'Humedad de suelo';
      case MetricType.airHumidity: return 'Humedad ambiental';
      case MetricType.temperature: return 'Temperatura';
      case MetricType.uvIndex: return 'Índice UV';
    }
  }
}
```

#### Device Entity

```dart
// lib/domain/entities/device.dart
import 'device_type.dart';

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final bool isActive;
  final DateTime createdAt;

  const Device({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
    required this.createdAt,
  });
}
```

#### Sensor Entity

```dart
// lib/domain/entities/sensor.dart
import 'metric_type.dart';

class Sensor {
  final String id;
  final String deviceId;
  final String name;
  final MetricType metric;
  final String unit;
  final double? minOk;
  final double? maxOk;
  final bool isActive;
  final DateTime createdAt;

  const Sensor({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.metric,
    required this.unit,
    this.minOk,
    this.maxOk,
    required this.isActive,
    required this.createdAt,
  });
}
```

#### DeviceRepository Contract

```dart
// lib/domain/repositories/device_repository.dart
import '../entities/device.dart';
import '../entities/device_type.dart';

/// Record type for register result: the device + its one-time API key.
typedef DeviceRegistration = ({Device device, String apiKey});

abstract class DeviceRepository {
  Future<List<Device>> getAll();
  Future<DeviceRegistration> register(String name, DeviceType type);
  Future<Device> revoke(String deviceId);
}
```

#### SensorManagementRepository Contract

```dart
// lib/domain/repositories/sensor_management_repository.dart
import '../entities/sensor.dart';
import '../entities/metric_type.dart';

abstract class SensorManagementRepository {
  Future<List<Sensor>> getAll();
  Future<List<Sensor>> getByDevice(String deviceId);
  Future<Sensor> create({
    required String deviceId,
    required String name,
    required MetricType metric,
    double? minOk,
    double? maxOk,
  });
  Future<Sensor> update({
    required String sensorId,
    String? name,
    double? minOk,
    double? maxOk,
    bool? isActive,
  });
}
```

---

### 2. Infrastructure Layer — DTOs

#### DeviceDto

```dart
// lib/infrastructure/models/device_dto.dart
import '../../domain/entities/device.dart';
import '../../domain/entities/device_type.dart';

class DeviceDto {
  final String id;
  final String name;
  final String type;
  final bool isActive;
  final String createdAt;

  const DeviceDto({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
    required this.createdAt,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) => DeviceDto(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    isActive: json['is_active'] as bool,
    createdAt: json['created_at'] as String,
  );

  Device toEntity() => Device(
    id: id,
    name: name,
    type: DeviceType.fromString(type),
    isActive: isActive,
    createdAt: DateTime.parse(createdAt),
  );
}
```

#### SensorDto

```dart
// lib/infrastructure/models/sensor_dto.dart
import '../../domain/entities/sensor.dart';
import '../../domain/entities/metric_type.dart';

class SensorDto {
  final String id;
  final String deviceId;
  final String name;
  final String metric;
  final String unit;
  final double? minOk;
  final double? maxOk;
  final bool isActive;
  final String createdAt;

  const SensorDto({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.metric,
    required this.unit,
    this.minOk,
    this.maxOk,
    required this.isActive,
    required this.createdAt,
  });

  factory SensorDto.fromJson(Map<String, dynamic> json) => SensorDto(
    id: json['id'] as String,
    deviceId: json['device_id'] as String,
    name: json['name'] as String,
    metric: json['metric'] as String,
    unit: json['unit'] as String,
    minOk: (json['min_ok'] as num?)?.toDouble(),
    maxOk: (json['max_ok'] as num?)?.toDouble(),
    isActive: json['is_active'] as bool,
    createdAt: json['created_at'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_id': deviceId,
    'name': name,
    'metric': metric,
    'unit': unit,
    'min_ok': minOk,
    'max_ok': maxOk,
    'is_active': isActive,
    'created_at': createdAt,
  };

  Sensor toEntity() => Sensor(
    id: id,
    deviceId: deviceId,
    name: name,
    metric: MetricType.fromString(metric),
    unit: unit,
    minOk: minOk,
    maxOk: maxOk,
    isActive: isActive,
    createdAt: DateTime.parse(createdAt),
  );
}
```

---

### 3. Infrastructure Layer — DataSources

#### DeviceRemoteDataSource Contract

```dart
// lib/infrastructure/datasources/device/device_remote_datasource.dart
import '../../models/device_dto.dart';

abstract class DeviceRemoteDataSource {
  Future<List<DeviceDto>> fetchAll();
  /// Returns raw JSON map including the one-time api_key.
  Future<Map<String, dynamic>> register(String name, String type);
  Future<DeviceDto> revoke(String deviceId);
}
```

#### DeviceRemoteDataSourceBackend

```dart
// lib/infrastructure/datasources/device/device_remote_datasource_backend.dart
import 'package:dio/dio.dart';
import '../../../domain/failures/app_failure.dart';
import '../../models/device_dto.dart';
import 'device_remote_datasource.dart';

class DeviceRemoteDataSourceBackend implements DeviceRemoteDataSource {
  final Dio _dio;

  DeviceRemoteDataSourceBackend(this._dio);

  @override
  Future<List<DeviceDto>> fetchAll() async {
    try {
      final response = await _dio.get('/devices');
      final list = response.data as List<dynamic>;
      return list.map((e) => DeviceDto.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<Map<String, dynamic>> register(String name, String type) async {
    try {
      final response = await _dio.post('/devices/register', data: {
        'name': name,
        'type': type,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final detail = e.response?.data?['detail'];
        final msg = detail is List ? detail.first['msg'] as String : '$detail';
        throw ValidationFailure(msg);
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<DeviceDto> revoke(String deviceId) async {
    try {
      final response = await _dio.patch('/devices/$deviceId/revoke');
      return DeviceDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundFailure('Dispositivo no encontrado');
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }
}
```

#### SensorRemoteManagementDataSource Contract

```dart
// lib/infrastructure/datasources/sensor/sensor_remote_management_datasource.dart
import '../../models/sensor_dto.dart';

abstract class SensorRemoteManagementDataSource {
  Future<List<SensorDto>> fetchAll();
  Future<List<SensorDto>> fetchByDevice(String deviceId);
  Future<SensorDto> create({
    required String deviceId,
    required String name,
    required String metric,
    double? minOk,
    double? maxOk,
  });
  Future<SensorDto> update(String sensorId, Map<String, dynamic> fields);
}
```

#### SensorRemoteManagementDataSourceBackend

```dart
// lib/infrastructure/datasources/sensor/sensor_remote_management_datasource_backend.dart
import 'package:dio/dio.dart';
import '../../../domain/failures/app_failure.dart';
import '../../models/sensor_dto.dart';
import 'sensor_remote_management_datasource.dart';

class SensorRemoteManagementDataSourceBackend implements SensorRemoteManagementDataSource {
  final Dio _dio;

  SensorRemoteManagementDataSourceBackend(this._dio);

  @override
  Future<List<SensorDto>> fetchAll() async {
    try {
      final response = await _dio.get('/sensors');
      final list = response.data as List<dynamic>;
      return list.map((e) => SensorDto.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<List<SensorDto>> fetchByDevice(String deviceId) async {
    try {
      final response = await _dio.get('/devices/$deviceId/sensors');
      final list = response.data as List<dynamic>;
      return list.map((e) => SensorDto.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundFailure('Dispositivo no encontrado');
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<SensorDto> create({
    required String deviceId,
    required String name,
    required String metric,
    double? minOk,
    double? maxOk,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'metric': metric,
      };
      if (minOk != null) body['min_ok'] = minOk;
      if (maxOk != null) body['max_ok'] = maxOk;

      final response = await _dio.post('/devices/$deviceId/sensors', data: body);
      return SensorDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final detail = e.response?.data?['detail'];
        final msg = detail is List ? detail.first['msg'] as String : '$detail';
        throw ValidationFailure(msg);
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<SensorDto> update(String sensorId, Map<String, dynamic> fields) async {
    try {
      final response = await _dio.patch('/sensors/$sensorId', data: fields);
      return SensorDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundFailure('Sensor no encontrado');
      }
      if (e.response?.statusCode == 422) {
        final detail = e.response?.data?['detail'];
        final msg = detail is List ? detail.first['msg'] as String : '$detail';
        throw ValidationFailure(msg);
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }
}
```

---

### 4. Infrastructure Layer — Repository Implementations

#### DeviceRepositoryImpl

```dart
// lib/infrastructure/repositories/device_repository_impl.dart
import '../../domain/entities/device.dart';
import '../../domain/entities/device_type.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/device/device_remote_datasource.dart';
import '../models/device_dto.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final DeviceRemoteDataSource _dataSource;

  DeviceRepositoryImpl(this._dataSource);

  @override
  Future<List<Device>> getAll() async {
    final dtos = await _dataSource.fetchAll();
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<DeviceRegistration> register(String name, DeviceType type) async {
    final raw = await _dataSource.register(name, type.name);
    final device = Device(
      id: raw['id'] as String,
      name: raw['name'] as String,
      type: DeviceType.fromString(raw['type'] as String),
      isActive: true,
      createdAt: DateTime.now(),
    );
    final apiKey = raw['api_key'] as String;
    return (device: device, apiKey: apiKey);
  }

  @override
  Future<Device> revoke(String deviceId) async {
    final dto = await _dataSource.revoke(deviceId);
    return dto.toEntity();
  }
}
```

#### SensorManagementRepositoryImpl

```dart
// lib/infrastructure/repositories/sensor_management_repository_impl.dart
import '../../domain/entities/sensor.dart';
import '../../domain/entities/metric_type.dart';
import '../../domain/repositories/sensor_management_repository.dart';
import '../datasources/sensor/sensor_remote_management_datasource.dart';

class SensorManagementRepositoryImpl implements SensorManagementRepository {
  final SensorRemoteManagementDataSource _dataSource;

  SensorManagementRepositoryImpl(this._dataSource);

  @override
  Future<List<Sensor>> getAll() async {
    final dtos = await _dataSource.fetchAll();
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<List<Sensor>> getByDevice(String deviceId) async {
    final dtos = await _dataSource.fetchByDevice(deviceId);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<Sensor> create({
    required String deviceId,
    required String name,
    required MetricType metric,
    double? minOk,
    double? maxOk,
  }) async {
    final dto = await _dataSource.create(
      deviceId: deviceId,
      name: name,
      metric: metric.toBackendString(),
      minOk: minOk,
      maxOk: maxOk,
    );
    return dto.toEntity();
  }

  @override
  Future<Sensor> update({
    required String sensorId,
    String? name,
    double? minOk,
    double? maxOk,
    bool? isActive,
  }) async {
    final fields = <String, dynamic>{};
    if (name != null) fields['name'] = name;
    if (minOk != null) fields['min_ok'] = minOk;
    if (maxOk != null) fields['max_ok'] = maxOk;
    if (isActive != null) fields['is_active'] = isActive;
    final dto = await _dataSource.update(sensorId, fields);
    return dto.toEntity();
  }
}
```

---

### 5. Provider Wiring

```dart
// lib/presentation/providers/device/device_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/device.dart';
import '../../../domain/entities/device_type.dart';
import '../../../domain/repositories/device_repository.dart';
import '../../../infrastructure/datasources/device/device_remote_datasource.dart';
import '../../../infrastructure/datasources/device/device_remote_datasource_backend.dart';
import '../../../infrastructure/network/dio_provider.dart';
import '../../../infrastructure/repositories/device_repository_impl.dart';

final deviceDataSourceProvider = Provider<DeviceRemoteDataSource>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return DeviceRemoteDataSourceBackend(dio);
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepositoryImpl(ref.watch(deviceDataSourceProvider));
});

/// AsyncNotifierProvider for the devices list + operations.
final devicesControllerProvider =
    AsyncNotifierProvider<DevicesController, List<Device>>(() => DevicesController());

class DevicesController extends AsyncNotifier<List<Device>> {
  @override
  Future<List<Device>> build() async {
    return ref.read(deviceRepositoryProvider).getAll();
  }

  Future<DeviceRegistration> registerDevice(String name, DeviceType type) async {
    final result = await ref.read(deviceRepositoryProvider).register(name, type);
    // Refresh list after registration
    ref.invalidateSelf();
    await future;
    return result;
  }

  Future<void> revokeDevice(String deviceId) async {
    await ref.read(deviceRepositoryProvider).revoke(deviceId);
    // Refresh list after revocation
    ref.invalidateSelf();
  }
}
```

```dart
// lib/presentation/providers/sensor/sensor_management_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/sensor.dart';
import '../../../domain/entities/metric_type.dart';
import '../../../domain/repositories/sensor_management_repository.dart';
import '../../../infrastructure/datasources/sensor/sensor_remote_management_datasource.dart';
import '../../../infrastructure/datasources/sensor/sensor_remote_management_datasource_backend.dart';
import '../../../infrastructure/network/dio_provider.dart';
import '../../../infrastructure/repositories/sensor_management_repository_impl.dart';

final sensorManagementDataSourceProvider = Provider<SensorRemoteManagementDataSource>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return SensorRemoteManagementDataSourceBackend(dio);
});

final sensorManagementRepositoryProvider = Provider<SensorManagementRepository>((ref) {
  return SensorManagementRepositoryImpl(ref.watch(sensorManagementDataSourceProvider));
});

/// AsyncNotifierProvider for the sensors list + CRUD operations.
final sensorsControllerProvider =
    AsyncNotifierProvider<SensorsController, List<Sensor>>(() => SensorsController());

class SensorsController extends AsyncNotifier<List<Sensor>> {
  @override
  Future<List<Sensor>> build() async {
    return ref.read(sensorManagementRepositoryProvider).getAll();
  }

  Future<void> createSensor({
    required String deviceId,
    required String name,
    required MetricType metric,
    double? minOk,
    double? maxOk,
  }) async {
    await ref.read(sensorManagementRepositoryProvider).create(
      deviceId: deviceId,
      name: name,
      metric: metric,
      minOk: minOk,
      maxOk: maxOk,
    );
    ref.invalidateSelf();
  }

  Future<void> updateSensor({
    required String sensorId,
    String? name,
    double? minOk,
    double? maxOk,
    bool? isActive,
  }) async {
    await ref.read(sensorManagementRepositoryProvider).update(
      sensorId: sensorId,
      name: name,
      minOk: minOk,
      maxOk: maxOk,
      isActive: isActive,
    );
    ref.invalidateSelf();
  }
}
```

---

### 6. Presentation Layer — Shared Widgets and Derived Providers

#### SensorTile Widget

```dart
// lib/presentation/widgets/sensor_tile.dart
import 'package:flutter/material.dart';
import '../../domain/entities/metric_type.dart';
import '../../domain/entities/sensor.dart';

/// Compact reusable widget showing basic sensor info.
/// Used in both the Sensors page (grouped by device) and
/// the Devices page (inside ExpansionTile).
class SensorTile extends StatelessWidget {
  const SensorTile({required this.sensor, this.trailing, this.onTap, super.key});

  final Sensor sensor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // ListTile with metric icon, name, subtitle with metric label + unit + threshold range
    // Default trailing: active/inactive Chip
  }
}
```

#### sensorsByDeviceProvider

```dart
// lib/presentation/providers/sensor/sensors_by_device_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/sensor.dart';
import 'sensor_management_providers.dart';

/// Derives a Map<deviceId, List<Sensor>> from sensorsControllerProvider.
/// No extra backend call — just reorganizes the same data.
final sensorsByDeviceProvider =
    Provider<AsyncValue<Map<String, List<Sensor>>>>((ref) {
  final sensorsAsync = ref.watch(sensorsControllerProvider);
  return sensorsAsync.whenData((sensors) {
    final grouped = <String, List<Sensor>>{};
    for (final sensor in sensors) {
      grouped.putIfAbsent(sensor.deviceId, () => []).add(sensor);
    }
    return grouped;
  });
});
```

### 7. Presentation Layer — Devices Page

```dart
// lib/presentation/pages/devices/devices_page.dart

/// Structure:
/// - Body: list of device cards using ExpansionTile
///   - Header: device name, type icon, status chip, creation date, sensor count
///   - Expanded children: SensorTile list (or "Sin sensores asignados" if empty)
///   - shape/collapsedShape set to Border() to remove default dividers
/// - FAB "Registrar dispositivo" → opens register dialog
/// - Active devices show a "Revocar" action button; disabled for inactive
/// - Loading/error states via AsyncValue.when()
class DevicesPage extends ConsumerWidget {
  // Uses devicesControllerProvider + sensorsByDeviceProvider
  // Register: showDialog → form (name TextField + DeviceType dropdown)
  //   → on success: shows ApiKeyDialog with copy button + warning
  // Revoke: showDialog → confirmation → calls revokeDevice(id)
}
```

**UI details:**
- Each device is a `Card` with `clipBehavior: Clip.antiAlias` wrapping an `ExpansionTile`
- `ExpansionTile` uses `shape: const Border()` and `collapsedShape: const Border()` to eliminate default top/bottom dividers
- Leading: device type icon; Title: device name; Subtitle: creation date + sensor count
- Trailing: status Chip + "Revocar" button
- Expanded children: list of `SensorTile` widgets for that device's sensors, or italic "Sin sensores asignados" text
- FAB "Registrar dispositivo" opens modal form
- API key dialog: prominent monospace text, "Copiar" button (Clipboard.setData), warning "Esta clave solo se muestra una vez"
- Revoke confirmation: AlertDialog with warning text, "Cancelar" and "Revocar" buttons
- Error states: SnackBar for operation failures, full-page error banner for list fetch failure

### 8. Presentation Layer — Sensors Page

```dart
// lib/presentation/pages/sensors/sensors_page.dart

/// Structure:
/// - Body: sensors grouped by device in visual card sections
///   - Each device group: Card with colored header showing device name/icon/count
///   - Sensor rows within each group use SensorTile with edit button
/// - FAB "Crear sensor" → opens creation dialog
/// - Loading/error states via AsyncValue.when()
class SensorsPage extends ConsumerWidget {
  // Uses sensorsByDeviceProvider + devicesControllerProvider (for device info + create form)
  // Create: showDialog → form (device dropdown [active only], name, metric dropdown, min_ok, max_ok)
  // Edit: showDialog → form prepopulated with current values (name, min_ok, max_ok)
}
```

**UI details:**
- Watches `sensorsByDeviceProvider` (grouped Map) and `devicesControllerProvider` (for device names/types)
- Each device group rendered as a `Card` with:
  - Header: `Container` with `surfaceContainerHighest` background, showing device icon + name + sensor count
  - Body: list of `SensorTile` widgets with custom trailing (status chip + "Editar" button)
- Create form: DropdownButtonFormField for device (active devices only), TextField for name, DropdownButtonFormField for MetricType, two optional TextFormFields for min_ok/max_ok
- Edit form: TextField name (prefilled), TextFormFields for min_ok/max_ok (prefilled, clearable)
- Clearing a threshold: if field is emptied, send null to backend

---

## File Changes Summary

| File | Action | Requirement |
|------|--------|-------------|
| `lib/domain/entities/device_type.dart` | **New** | R1 |
| `lib/domain/entities/metric_type.dart` | **New** | R2 |
| `lib/domain/entities/device.dart` | **New** | R1 |
| `lib/domain/entities/sensor.dart` | **New** | R2 |
| `lib/domain/repositories/device_repository.dart` | **New** | R3 |
| `lib/domain/repositories/sensor_management_repository.dart` | **New** | R4 |
| `lib/infrastructure/models/device_dto.dart` | **New** | R5 |
| `lib/infrastructure/models/sensor_dto.dart` | **New** | R6 |
| `lib/infrastructure/datasources/device/device_remote_datasource.dart` | **New** | R7 |
| `lib/infrastructure/datasources/device/device_remote_datasource_backend.dart` | **New** | R7 |
| `lib/infrastructure/datasources/sensor/sensor_remote_management_datasource.dart` | **New** | R8 |
| `lib/infrastructure/datasources/sensor/sensor_remote_management_datasource_backend.dart` | **New** | R8 |
| `lib/infrastructure/repositories/device_repository_impl.dart` | **New** | R9 |
| `lib/infrastructure/repositories/sensor_management_repository_impl.dart` | **New** | R9 |
| `lib/presentation/providers/device/device_providers.dart` | **New** | R9, R10-R12 |
| `lib/presentation/providers/sensor/sensor_management_providers.dart` | **New** | R9, R13-R15 |
| `lib/presentation/providers/sensor/sensors_by_device_provider.dart` | **New** | R13 |
| `lib/presentation/widgets/sensor_tile.dart` | **New** | R10, R13 |
| `lib/presentation/pages/devices/devices_page.dart` | Rewrite (replace placeholder) | R10-R12, R16 |
| `lib/presentation/pages/sensors/sensors_page.dart` | Rewrite (replace placeholder) | R13-R15, R16 |

## Key Design Decisions

1. **Separate from existing SensorRepository** — The existing `SensorRepository`/`SensorRemoteDataSource` handles readings (time-series data). This new `SensorManagementRepository` handles sensor metadata CRUD. They coexist without conflict.
2. **`authenticatedDioProvider` for all calls** — No new Dio instance needed. The existing interceptor handles token attachment and refresh transparently.
3. **DeviceRegistration as a Dart record** `({Device device, String apiKey})` — Clean way to return both pieces from the register method without creating a throwaway class.
4. **Controllers use `ref.invalidateSelf()`** — After a mutation (register, revoke, create, update), the controller invalidates itself to re-fetch the fresh list. Simple and correct.
5. **Sensors page groups by device** — Uses `sensorsByDeviceProvider` (derived from `sensorsControllerProvider` via `whenData`) to group sensors by `deviceId` without an extra backend call. The UI renders each group as a card with a device header.
6. **Devices page shows sensors via ExpansionTile** — Each device card is expandable to reveal its associated sensors inline, using the same `sensorsByDeviceProvider` and the shared `SensorTile` widget.
7. **Shared `SensorTile` widget** — A compact, reusable `ListTile`-based widget used in both the Sensors page (within device groups) and the Devices page (inside ExpansionTile children). Accepts an optional `trailing` widget for context-specific actions.
8. **ExpansionTile dividers removed** — `shape: const Border()` and `collapsedShape: const Border()` eliminate the default top/bottom divider lines that look jarring in dark themes.
9. **MetricType.toBackendString()** — Explicit conversion instead of relying on `.name` (which would give camelCase instead of snake_case).
10. **Register API key dialog** — Shown immediately after successful registration with a prominent copy button and a "shown only once" warning. No persistence of the key in the frontend.
11. **Revoke is destructive** — Requires confirmation dialog before execution. Disabled (greyed out) for already-inactive devices.
