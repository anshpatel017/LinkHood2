import 'package:flutter/material.dart';
import '../../../../core/widgets/empty_state_widget.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Mark all as read
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: const EmptyStateWidget(
        icon: Icons.notifications_none,
        title: 'No notifications',
        subtitle: 'You\'ll receive alerts for rental requests, approvals, and neighbor broadcasts.',
      ),
    );
  }
}
