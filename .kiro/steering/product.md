---
inclusion: always
---

# Visión del producto: Panel IoT — Jitomates Cherry

## Qué es
Aplicación web (Flutter Web) que funciona como panel de control para un sistema IoT casero de monitoreo y control de un cultivo de jitomate cherry. Permite ver en tiempo real el estado de las plantas, revisar históricos, y (a futuro) controlar actuadores y ver video en vivo.

## Para quién
Uso personal. No es un producto multiusuario ni comercial por ahora. El diseño debe priorizar simplicidad y mantenibilidad sobre escalabilidad a gran escala.

## Problema que resuelve
Hoy el monitoreo de las plantas es manual. El panel centraliza las lecturas de sensores para detectar problemas (estrés por calor, riego insuficiente) sin revisar físicamente las plantas todo el tiempo.

## Alcance actual (MVP)
- Login simple (un usuario, o pocos usuarios de confianza).
- Lectura en tiempo real de:
  - Temperatura
  - Humedad de suelo
- Histórico de esas lecturas con gráficas.
- Alertas visuales cuando un valor sale del rango saludable para jitomate cherry.

## Roadmap (fuera del MVP — NO implementar todavía)
- Control remoto de una bomba de riego desde el dashboard (actuador).
- Video en vivo de la planta integrado en el dashboard.
- Posiblemente más sensores (humedad ambiente, luz, pH) si se agregan al hardware.

> Nota para Kiro: no construir las features de "roadmap" hasta que exista un spec específico para ellas (ej. `.kiro/specs/control-bomba/`, `.kiro/specs/video-en-vivo/`). El objetivo del MVP es únicamente el dashboard de monitoreo + login.

## Restricciones importantes
- El proveedor de persistencia (base de datos/backend) **todavía no está decidido**. La arquitectura debe permitir cambiarlo sin tocar el dominio ni la UI (ver `architecture.md`).
- Proyecto de aprendizaje personal: prioriza código claro y explicable sobre abstracciones que no se necesiten todavía.
