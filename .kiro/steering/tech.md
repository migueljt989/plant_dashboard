---
inclusion: always
---

# Stack tecnológico

## Frontend
- **Framework:** Flutter (Web). Un solo target por ahora, sin mobile/desktop.
- **Enrutamiento:** `go_router`. Es la única librería de rutas permitida.
- **Manejo de estado:** Riverpod, **sin code generation** (usar `Provider`, `NotifierProvider`, `AsyncNotifierProvider`, `StreamProvider`, etc. de forma explícita, sin `riverpod_generator`/`build_runner`). Motivo: aprendizaje — preferimos ver el código escrito a mano antes de introducir codegen. Se puede migrar más adelante si el proyecto crece.
- **Gráficas:** `fl_chart` para el histórico de sensores.
- **HTTP/red:** `dio` (no `http` plano) — facilita interceptores y nos da más control al cambiar entre datasources.
- **Serialización JSON:** manual (`fromJson`/`toJson` escritos a mano en los DTOs). El número de entidades es pequeño; no se justifica `freezed`/`json_serializable` todavía.

## Backend / persistencia
- **Aún no decidido.** Candidatos abiertos: AWS (IoT Core + DynamoDB), Firebase/Firestore, o una API REST propia.
- La app **no debe** depender directamente de ningún SDK de backend en `domain` ni en `presentation`. Esa dependencia vive únicamente detrás de un `DataSource` en `infrastructure` (ver `architecture.md`).
- Mientras no haya backend real conectado, usar una implementación de `DataSource` en memoria ("fake") que simule lecturas, para no bloquear el desarrollo de la UI.

## Autenticación
- Login simple. El proveedor concreto aún no está decidido (puede acabar siendo el mismo que el de persistencia, ej. Firebase Auth o Cognito, o algo propio con JWT). Igual que la persistencia, vive detrás de un `AuthRepository` abstracto en `domain`.

## Futuro (no implementar todavía, solo para contexto)
- Bomba de riego: requerirá un `ActuatorRepository` + comando enviado al backend (no diseñar esto aún, solo tenerlo en mente al nombrar cosas para no chocar después).
- Video en vivo: probablemente `webview_flutter`, `video_player` con HLS, o un `<img>` MJPEG embebido en Flutter Web, dependiendo de qué exponga el backend. Decisión pendiente hasta que exista ese spec.

## Herramientas de desarrollo
- Kiro (AWS) como IDE con agente, modelo Sonnet del free tier (50 créditos/mes). Por eso los steering files de detalle usan `inclusion: fileMatch` en vez de `always` (ver cada archivo).

## Decisiones explícitas que Kiro NO debe cambiar sin pedir confirmación
- `go_router` (no Navigator 2.0 manual, no otra librería de rutas).
- Riverpod sin codegen (no Bloc, no Provider clásico, no GetX, no riverpod_generator por ahora).
- Patrón Repository + DataSource para toda persistencia (ver `architecture.md`).
