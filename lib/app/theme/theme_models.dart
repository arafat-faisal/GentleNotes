import 'package:flutter/material.dart';

class CustomAccentColor {
  final String name;
  final String hex;
  final Color color;

  const CustomAccentColor({
    required this.name,
    required this.hex,
    required this.color,
  });
}

const List<CustomAccentColor> kAccentColors = [
  CustomAccentColor(
    name: 'Gentle Indigo',
    hex: '#6366F1',
    color: Color(0xFF6366F1),
  ),
  CustomAccentColor(
    name: 'Forest Emerald',
    hex: '#10B981',
    color: Color(0xFF10B981),
  ),
  CustomAccentColor(
    name: 'Ocean Sapphire',
    hex: '#3B82F6',
    color: Color(0xFF3B82F6),
  ),
  CustomAccentColor(
    name: 'Blossom Coral',
    hex: '#F43F5E',
    color: Color(0xFFF43F5E),
  ),
  CustomAccentColor(
    name: 'Sunset Amber',
    hex: '#F59E0B',
    color: Color(0xFFF59E0B),
  ),
];
