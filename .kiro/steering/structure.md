---
inclusion: always
---

# Estructura del proyecto

## Árbol de carpetas (dentro de `lib/`)

```
lib/
  core/
    config/            # configuración de entorno (.env, flavors)
    error/             # Failure y excepciones de dominio
    theme/             # tema visual de la app
    utils/             # helpers genéricos sin reglas de negocio
  domain/
    entities/          # objetos de negocio puros (sin Json, sin Flutter)
    repositories/      # contratos abstractos (interfaces)
    failures/          # tipos de error de dominio
  infrastructure/
    datasources/
      <feature>/                              # ej: sensor/, auth/
        <feature>_datasource.dart             # contrato abstracto del datasource
        <feature>_datasource_<impl>.dart      # implementación concreta (_fake, _rest, _dynamodb...)
    models/             # DTOs con fromJson/toJson + mapper toEntity()
    repositories/       # implementaciones de domain/repositories;
                         # cada una recibe un DataSource por constructor
  presentation/
    router/
      app_router.dart   # configuración de go_router
      app_routes.dart    # constantes de rutas
    providers/
      <feature>/          # providers de riverpod agrupados por feature
    pages/
      splash/              # pantalla de carga (restauración de sesión)
      <feature>/           # una carpeta por pantalla/feature
    widgets/                # widgets compartidos entre features
  main.dart
  app.dart                   # ProviderScope + MaterialApp.router
```

## Reglas de dependencia (importante)
- `domain` no importa nada de `infrastructure` ni de `presentation`, ni de Flutter, ni de paquetes de red/JSON.
- `infrastructure` puede importar `domain` (implementa sus contratos), pero nunca al revés.
- `presentation` importa `domain` (para tipos) y usa `infrastructure` **solo a través de providers**, nunca instanciando una implementación concreta dentro de un widget.

## Convenciones de nombres
- Archivos: `snake_case.dart`.
- Clases: `PascalCase`.
- Entidades de dominio: nombre simple, sin sufijo (`SensorReading`, no `SensorReadingEntity`).
- Contratos de repositorio: sufijo `Repository` (`SensorRepository`).
- Implementaciones de repositorio: sufijo `RepositoryImpl` (`SensorRepositoryImpl`).
- Contratos de datasource: sufijo `DataSource` (`SensorRemoteDataSource`).
- Implementaciones de datasource: sufijo describiendo el proveedor (`SensorRemoteDataSourceFake`, `SensorRemoteDataSourceRest`).
- DTOs: sufijo `Dto` (`SensorReadingDto`).
- Providers de Riverpod: sufijo `Provider` (`sensorRepositoryProvider`, `dashboardControllerProvider`).

## Una carpeta por feature, no por tipo de archivo
Dentro de `presentation/pages` y `presentation/providers`, organiza por feature (ej. `dashboard/`, `auth/`) y no por tipo de widget. Esto facilita borrar o mover una feature completa sin tocar el resto.
