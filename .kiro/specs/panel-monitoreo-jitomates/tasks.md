# Implementation Plan: Panel de Monitoreo (MVP)

## Overview

Plan de implementación para el MVP del panel de monitoreo IoT de jitomates cherry. Cubre autenticación simple, lecturas en tiempo real, histórico con gráficas, alertas visuales, tema oscuro centralizado, y arquitectura de datos intercambiable.

## Tasks

- [x] 1. Configurar dependencias en el proyecto Flutter existente: flutter_riverpod, go_router, fl_chart, dio
  - El proyecto Flutter ya existe. Solo agregar las dependencias al `pubspec.yaml` y verificar que `flutter run -d chrome` sigue funcionando.
  - _Requisitos: 5.1_

- [x] 2. Crear estructura de carpetas domain/infrastructure/presentation según structure.md
  - _Requisitos: 5.1, 5.2_

- [x] 3. Definir entidades de dominio: SensorReading, AppUser, AlertThreshold
  - _Requisitos: 2.1, 4.2, 5.1_

- [x] 4. Definir contratos SensorRepository y AuthRepository
  - _Requisitos: 1.1, 2.1, 5.1_

- [x] 5. Implementar SensorRemoteDataSourceFake (lecturas simuladas) y AuthRemoteDataSourceFake
  - _Requisitos: 5.3_

- [x] 6. Implementar SensorRepositoryImpl y AuthRepositoryImpl sobre los datasources fake
  - _Requisitos: 5.2_

- [x] 7. Configurar providers de Riverpod (datasource → repository) para sensores y auth
  - _Requisitos: 5.2_

- [x] 8. Configurar go_router con rutas /login y / (dashboard), con redirect según authControllerProvider
  - _Requisitos: 1.1, 1.2_

- [ ] 9. Crear `core/config/app_theme.dart` con tema oscuro y paleta AppColors; aplicar en `app.dart`
  - Crear el archivo `core/config/app_theme.dart` con `AppColors` y `appTheme` según el diseño.
  - Actualizar `app.dart` para pasar `theme: appTheme` y `themeMode: ThemeMode.dark` a `MaterialApp.router`.
  - Verificar que ningún widget existente tenga colores hardcodeados; migrar a `Theme.of(context)` donde sea necesario.
  - _Requisitos: 6.1, 6.2, 6.3_

- [x] 10. Construir LoginPage (formulario simple + manejo de error de credenciales)
  - _Requisitos: 1.2, 1.3_

- [x] 11. Construir DashboardPage mostrando la última lectura (StreamProvider) con estado de carga/error
  - _Requisitos: 2.1, 2.2, 2.3, 2.4_

- [x] 12. Agregar selector de rango de fechas + gráfica histórica con fl_chart
  - _Requisitos: 3.1, 3.2, 3.3_

- [x] 13. Agregar lógica de alerta visual usando AlertThreshold configurable
  - _Requisitos: 4.1, 4.2_

- [x] 14. Mantener la sesión entre recargas (persistir token/estado de auth)
  - _Requisitos: 1.4_

- [ ] 15. Pruebas unitarias de SensorRepositoryImpl y AuthRepositoryImpl contra sus datasources fake
  - _Requisitos: 5.2, 5.3_

## Task Dependency Graph

```
1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 10 → 11 → 12 → 13 → 14 → 15
                                   ↗
                               9 (independiente, puede hacerse en paralelo con 8–14)
```

## Notes

- La tarea 9 (tema oscuro) es independiente de la lógica de negocio y puede implementarse en cualquier momento a partir de la tarea 2.
- Las tareas 1–8 ya están completadas. Las pendientes son la 9 (tema), 15 (pruebas), y cualquier ajuste derivado del nuevo tema.
- La persistencia de sesión (tarea 14) depende de tener un backend real; con el fake la sesión se pierde en cada recarga — comportamiento aceptable para el MVP.
