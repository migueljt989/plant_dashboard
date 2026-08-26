import 'package:flutter/material.dart';

/// Paleta de colores del panel (dark mode, evocando vegetación).
///
/// Todos los widgets deben referenciar estas constantes o los valores del
/// [appTheme] a través de `Theme.of(context)`. Ningún widget debe definir
/// colores ni estilos como literales (`Color(0xFF...)`, `Colors.green`, etc.).
///
/// Requisito 6.2: valores visuales centralizados aquí.
/// Requisito 6.4: paleta de verdes oscuros + fondos oscuros neutros.
abstract class AppColors {
  // ── Fondos ─────────────────────────────────────────────────────────────
  /// Fondo principal del Scaffold.
  static const background = Color(0xFF121212);

  /// Superficie de cards y paneles.
  static const surface = Color(0xFF1E1E1E);

  /// Filas alternas, dividers, chips y fondos secundarios.
  static const surfaceAlt = Color(0xFF2C2C2C);

  // ── Primario — verde oscuro ─────────────────────────────────────────────
  /// Acento principal (botones, bordes activos, íconos de marca).
  static const primary = Color(0xFF388E3C);

  /// Hover / highlight / lecturas en rango.
  static const primaryLight = Color(0xFF66BB6A);

  // ── Estado ─────────────────────────────────────────────────────────────
  /// Alerta fuera de rango (valor demasiado alto).
  static const warning = Color(0xFFFFA726);

  /// Error crítico (valor demasiado bajo).
  static const error = Color(0xFFEF5350);

  /// Lectura dentro del rango saludable.
  static const ok = Color(0xFF66BB6A);

  // ── Texto ───────────────────────────────────────────────────────────────
  /// Texto principal (títulos, valores destacados).
  static const textPrimary = Color(0xFFE0E0E0);

  /// Texto secundario (etiquetas, metadatos, subtítulos).
  static const textSecondary = Color(0xFF9E9E9E);
}

/// [ThemeData] listo para pasar a `MaterialApp.router(theme: appTheme)`.
///
/// Requisito 6.1: tema oscuro (Brightness.dark).
/// Requisito 6.2: único archivo de configuración visual.
final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    surface: AppColors.surface,
    surfaceTint: Colors.transparent,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSurface: AppColors.textPrimary,
  ),
  scaffoldBackgroundColor: AppColors.background,
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    linearMinHeight: 4,
  ),
  cardTheme: const CardThemeData(color: AppColors.surface),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
  ),
  chipTheme: const ChipThemeData(
    backgroundColor: AppColors.surfaceAlt,
    labelStyle: TextStyle(color: AppColors.textPrimary),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.surfaceAlt,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.textPrimary),
    bodyMedium: TextStyle(color: AppColors.textSecondary),
    bodySmall: TextStyle(color: AppColors.textSecondary),
    titleMedium: TextStyle(color: AppColors.textPrimary),
    titleSmall: TextStyle(color: AppColors.textSecondary),
  ),
);
