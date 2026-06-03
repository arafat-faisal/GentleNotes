import 'package:flutter/material.dart';
import '../../../../../../models/models.dart';
import '../../subscription_panel.dart';

class SubscriptionStatusCard extends StatelessWidget {
  final UserRole activeRole;

  const SubscriptionStatusCard({
    super.key,
    required this.activeRole,
  });

  @override
  Widget build(BuildContext context) {
    return SubscriptionPanel(activeRole: activeRole);
  }
}
