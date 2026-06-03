import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AboutSettingsSection extends StatelessWidget {
  const AboutSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.info_outline_rounded),
      title: const Text('About Gentle Notes'),
      subtitle: const Text('V1.0.0 (MVP Build)'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => context.push('/about'),
    );
  }
}
