# Documento de Requisitos — Panel de Monitoreo (MVP)

## Introducción
Este spec cubre el MVP del panel: login simple, lecturas en tiempo real de temperatura y humedad de suelo, histórico con gráficas, y alertas por rango. No cubre control de bomba ni video en vivo (quedan para specs futuros, ver `product.md`).

## Requisitos

### Requisito 1: Autenticación simple
**Historia de usuario:** Como dueño del huerto, quiero iniciar sesión antes de ver el panel, para que solo personas autorizadas vean y eventualmente controlen el sistema.

Criterios de aceptación:
1. CUANDO un usuario no autenticado intenta acceder a cualquier ruta protegida, EL SISTEMA DEBERÁ redirigirlo a la pantalla de login.
2. CUANDO un usuario ingresa credenciales válidas, EL SISTEMA DEBERÁ autenticarlo y redirigirlo al dashboard.
3. CUANDO un usuario ingresa credenciales inválidas, EL SISTEMA DEBERÁ mostrar un mensaje de error sin revelar si el problema fue el usuario o la contraseña.
4. EL SISTEMA DEBERÁ mantener la sesión activa entre recargas de la página mientras el token/sesión sea válido.

### Requisito 2: Lectura en tiempo real
**Historia de usuario:** Como dueño del huerto, quiero ver la temperatura y humedad de suelo actuales, para conocer el estado de mis plantas sin revisarlas físicamente.

Criterios de aceptación:
1. CUANDO el usuario abre el dashboard, EL SISTEMA DEBERÁ mostrar la última lectura disponible de temperatura y humedad de suelo.
2. EL SISTEMA DEBERÁ actualizar la lectura mostrada automáticamente sin que el usuario tenga que recargar la página.
3. SI la fuente de datos no responde, ENTONCES EL SISTEMA DEBERÁ mostrar un estado de error explícito en vez de datos congelados sin aviso.
4. EL SISTEMA DEBERÁ mostrar la fecha/hora de la última lectura recibida.

### Requisito 3: Histórico con gráficas
**Historia de usuario:** Como dueño del huerto, quiero ver el histórico de temperatura y humedad de suelo en una gráfica, para identificar tendencias y problemas pasados.

Criterios de aceptación:
1. CUANDO el usuario selecciona un rango de fechas, EL SISTEMA DEBERÁ mostrar una gráfica con las lecturas de ese rango.
2. SI no hay datos en el rango seleccionado, ENTONCES EL SISTEMA DEBERÁ mostrar un mensaje indicándolo en vez de una gráfica vacía sin explicación.
3. EL SISTEMA DEBERÁ mostrar temperatura y humedad de suelo en la misma vista, diferenciadas claramente (ej. colores o ejes distintos).

### Requisito 4: Alertas por rango
**Historia de usuario:** Como dueño del huerto, quiero que el panel resalte cuando un valor está fuera de rango saludable, para poder actuar a tiempo.

Criterios de aceptación:
1. CUANDO una lectura de temperatura o humedad de suelo esté fuera del rango configurado como saludable, EL SISTEMA DEBERÁ resaltar visualmente esa lectura (ej. color de advertencia).
2. EL SISTEMA DEBERÁ permitir que los rangos saludables sean valores configurables, no hardcodeados en widgets de presentación.

### Requisito 5 (técnico/no funcional): Persistencia intercambiable
**Historia de usuario:** Como desarrollador del proyecto, quiero que la fuente de datos pueda cambiarse sin modificar el dominio ni la presentación, porque aún no he decidido el proveedor definitivo de backend.

Criterios de aceptación:
1. EL SISTEMA DEBERÁ definir las lecturas y la autenticación como contratos de repositorio en `domain`, independientes del proveedor de datos.
2. EL SISTEMA DEBERÁ implementar el acceso a datos a través de un `DataSource` reemplazable en `infrastructure`, siguiendo `architecture.md`.
3. MIENTRAS no exista un backend real conectado, EL SISTEMA DEBERÁ funcionar con una implementación de `DataSource` en memoria (fake) que simule lecturas.

### Requisito 6 (no funcional): Tema visual oscuro centralizado

**Historia de usuario:** Como desarrollador del proyecto, quiero que el tema visual de la aplicación esté centralizado en un único archivo en `core/config/`, para poder cambiar colores, tipografías y estilos de forma global sin buscar valores dispersos por los widgets.

Criterios de aceptación:
1. EL SISTEMA DEBERÁ aplicar un tema oscuro (`ThemeMode.dark`) como tema por defecto de la aplicación.
2. EL SISTEMA DEBERÁ definir todos los valores visuales (colores, tipografía, estilos de componentes) en un único archivo `core/config/app_theme.dart`, exportando un `ThemeData` listo para usar en `MaterialApp.router`.
3. LOS WIDGETS no deberán contener colores, tamaños de fuente ni estilos hardcodeados — deberán usar los valores del tema a través de `Theme.of(context)` o constantes exportadas desde `core/config/app_theme.dart`.
4. EL SISTEMA DEBERÁ usar una paleta basada en verdes oscuros (evocando vegetación) y fondos oscuros neutros, acorde al contexto de monitoreo de plantas.

## Fuera de alcance (specs futuros)
- Control remoto de bomba de riego (actuador).
- Video en vivo de la planta.
- Sensores adicionales (humedad ambiente, luz, pH).
