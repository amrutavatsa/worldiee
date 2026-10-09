import 'package:flutter/material.dart';

abstract final class WorldCompanionColors {
  // Brand
  static const deepOcean = Color(0xFF0B2545);
  static const navyBlue = Color(0xFF13315C);
  static const oceanBlue = Color(0xFF134074);
  static const softBlue = Color(0xFF8DA9C4);
  static const softWhite = Color(0xFFEEF4ED);

  // Neutrals
  static const surface = Color(0xFFFFFFFF);
  static const primaryText = deepOcean;
  static const secondaryText = Color(0xFF4B6075);
  static const mutedText = Color(0xFF718398);
  static const border = Color(0xFFD6E0E8);

  // Semantic
  static const success = Color(0xFF2E7D5B);
  static const warning = Color(0xFFC58A2A);
  static const error = Color(0xFFC94B4B);
  static const info = oceanBlue;

  // Special surfaces
  static const aiSurface = Color(0xFFF2F6FA);
  static const mapSurface = Color(0xFFEAF0F5);
  static const successSurface = Color(0xFFEAF6F0);
  static const warningSurface = Color(0xFFFFF7E8);
  static const errorSurface = Color(0xFFFFEEEE);
  static const infoSurface = Color(0xFFEDF4FA);
}