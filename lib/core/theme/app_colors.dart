/// Centralized color palette for GentleNotes.
///
/// All colors used across the app are defined here, organized by role.
/// Screens and widgets import this file instead of hardcoding hex values,
/// making theme changes a single-file operation.
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Prevent instantiation

  // ── Dark Palette ─────────────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF090B16);
  static const Color darkSurface = Color(0xFF10121F);
  static const Color darkCard = Color(0xFF13111C);
  static const Color darkBorder = Color(0xFF252234);
  static const Color darkSurface2 = Color(0xFF1A1730);

  // ── Light Palette ────────────────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF5F3FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFAF9FF);
  static const Color lightBorder = Color(0xFFE9E6F5);

  // ── Primary Accent: Violet ───────────────────────────────────────────────────
  static const Color violet = Color(0xFF7C3AED);
  static const Color violetLight = Color(0xFF8B5CF6);
  static const Color violetBright = Color(0xFFA78BFA);
  static const Color violetMuted = Color(0xFF6D28D9);

  // ── Secondary Accents ────────────────────────────────────────────────────────
  static const Color rose = Color(0xFFF43F5E);
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color sky = Color(0xFF38BDF8);
  static const Color indigo = Color(0xFF6366F1);

  // ── Text Colors (Light) ──────────────────────────────────────────────────────
  static const Color lightTextPrimary = Color(0xFF1A0F3C);
  static const Color lightTextSecondary = Color(0xFF2D1F6E);
  static const Color lightTextTertiary = Color(0xFF5E4D8C);
  static const Color lightTextMuted = Color(0xFF7B6BA8);
  static const Color lightTextHint = Color(0xFFAA9ECC);

  // ── Text Colors (Dark) ───────────────────────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFF1EFF9);
  static const Color darkTextSecondary = Color(0xFFE2DBF5);
  static const Color darkTextTertiary = Color(0xFFB9B0D6);
  static const Color darkTextMuted = Color(0xFF9088B5);
  static const Color darkTextHint = Color(0xFF6B5F8A);

  // ── Note Tint Colors ─────────────────────────────────────────────────────────
  // Soft background tints used on note cards.
  static const Color tintBlue = Color(0xFFE0F2FE);
  static const Color tintRose = Color(0xFFFFF1F2);
  static const Color tintGreen = Color(0xFFECFDF5);
  static const Color tintPurple = Color(0xFFF3E8FF);
  static const Color tintAmber = Color(0xFFFEF3C7);
  static const Color tintSoftPurple = Color(0xFFFDF4FF);
}
