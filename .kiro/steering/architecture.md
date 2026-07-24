---
inclusion: fileMatch
fileMatchPattern: 'lib/**/*.dart'
---

# Arquitectura: Clean Architecture + Repository/DataSource intercambiable

Este es el patrón más importante del proyecto. El objetivo: poder cambiar el proveedor de persistencia (AWS, Firebase, REST propio, lo que sea) **sin tocar `domain` ni `presentation`**, y casi sin tocar `infrastructure/repositories`.

## Las 3 capas

1. **domain**: entidades + contratos (`abstract class`). No sabe nada de cómo se obtienen los datos.
2. **infrastructure**: implementa los contratos de domain (`...RepositoryImpl`) y define los `DataSource` (también contratos + implementaciones concretas).
3. **presentation**: consume `domain` a través de providers de Riverpod. No conoce ninguna implementación concreta.

## Por qué hay DataSource Y Repository (no es lo mismo)
- El **Repository** (contrato en `domain`, implementación en `infrastructure`) habla en términos de **entidades de dominio** (`SensorReading`). Es lo único que `presentation` conoce.
- El **DataSource** habla en términos de **datos crudos** del proveedor (JSON de una API REST, un documento de Firestore, un item de DynamoDB). Nunca expone tipos de domain directamente — expone DTOs.
- El `RepositoryImpl` recibe un `DataSource` por constructor y se encarga de convertir DTO → Entity.

Esto es lo que permite cambiar de AWS a Firebase sin dolor: solo escribes un nuevo `DataSource`, el `RepositoryImpl` no cambia.

## Ejemplo de referencia: lecturas de sensores

```dart
// domain/entities/sensor_reading.dart
class SensorReading {
  final String deviceId;
  final double temperature;
  final double soilMoisture;
  final DateTime recordedAt;

  const SensorReading({
    required this.deviceId,
    required this.temperature,
    required this.soilMoisture,
    required this.recordedAt,
  });
}

// domain/repositories/sensor_repository.dart
abstract class SensorRepository {
  Future<SensorReading> getLatestReading(String deviceId);
  Stream<SensorReading> watchLatestReading(String deviceId);
  Future<List<SensorReading>> getHistory(String deviceId, DateTimeRange range);
}
```

```dart
// infrastructure/datasources/sensor/sensor_remote_datasource.dart
abstract class SensorRemoteDataSource {
  Future<SensorReadingDto> fetchLatest(String deviceId);
  Stream<SensorReadingDto> streamLatest(String deviceId);
  Future<List<SensorReadingDto>> fetchHistory(String deviceId, DateTimeRange range);
}

// infrastructure/datasources/sensor/sensor_remote_datasource_fake.dart
// -> implementación en memoria, útil mientras no hay backend real.

// infrastructure/datasources/sensor/sensor_remote_datasource_rest.dart
// -> implementación real contra una API REST (o el SDK que se elija a futuro).
```

```dart
// infrastructure/repositories/sensor_repository_impl.dart
class SensorRepositoryImpl implements SensorRepository {
  final SensorRemoteDataSource _dataSource;
  SensorRepositoryImpl(this._dataSource);

  @override
  Future<SensorReading> getLatestReading(String deviceId) async {
    final dto = await _dataSource.fetchLatest(deviceId);
    return dto.toEntity();
  }
  // ...el resto de métodos: delega al datasource y mapea DTO -> Entity.
}
```

## Cómo se conecta con Riverpod (el "switch" de proveedor)
El único lugar donde se decide **qué implementación concreta se usa** es un provider:

```dart
// infrastructure/datasources/sensor/sensor_datasource_provider.dart
final sensorRemoteDataSourceProvider = Provider<SensorRemoteDataSource>((ref) {
  return SensorRemoteDataSourceFake(); // <- cambiar aquí cuando exista backend real
});

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  final dataSource = ref.watch(sensorRemoteDataSourceProvider);
  return SensorRepositoryImpl(dataSource);
});
```

Cambiar de proveedor = cambiar una línea dentro de `sensorRemoteDataSourceProvider`. Nada en `presentation` se entera.

## Reglas para Kiro al generar código
- Nunca instanciar un `...RepositoryImpl` ni un `...DataSource` concreto dentro de un widget o de una página. Siempre a través de un provider.
- Toda nueva feature de datos sigue el mismo patrón: entidad → contrato de repositorio → contrato de datasource → DTO con mapper → implementación(es) → provider que las conecta.
- Si todavía no hay backend decidido para una feature nueva, crear primero la implementación `Fake` (en memoria) para no bloquear el desarrollo de la UI.
- No agregar capas/abstracciones que no se pidieron (ej. no agregar UseCases a menos que el flujo combine más de un repositorio o tenga lógica de negocio no trivial).
