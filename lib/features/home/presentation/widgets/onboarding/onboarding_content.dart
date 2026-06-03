import 'package:flutter/material.dart';

class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
  });
}

final List<OnboardingPageData> onboardingPages = [
  OnboardingPageData(
    title: 'Beautiful Folder Organization',
    description: 'Create custom folders and nested directories with color codes and unique icons. Keep your ideas, learning, and projects clean.',
    icon: Icons.folder_copy_outlined,
    gradientColors: [Colors.indigo, Colors.blue],
  ),
  OnboardingPageData(
    title: 'Built-in Templates',
    description: 'Start writing immediately with structured templates for AI/ML learning, hackathons, meeting notes, code snippets, and research logs.',
    icon: Icons.assignment_outlined,
    gradientColors: [const Color(0xFF10B981), Colors.teal],
  ),
  OnboardingPageData(
    title: 'Import, Export & Share',
    description: 'Export your notes as beautiful Markdown or cross-platform JSON. Import shared notes and templates from team members instantly.',
    icon: Icons.share_outlined,
    gradientColors: [const Color(0xFFF43F5E), Colors.orange],
  ),
];
