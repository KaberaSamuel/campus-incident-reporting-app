import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../profile/models/user_role.dart';
import '../repositories/notification_repository.dart';

/// Inbox icon for the bottom bar with a live unread-count badge.
class InboxNavIcon extends StatelessWidget {
  const InboxNavIcon({super.key, this.selected = false});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid;
    final icon = Icon(selected ? Icons.inbox : Icons.inbox_outlined);
    if (uid == null) return icon;

    return StreamBuilder<int>(
      stream: context.read<NotificationRepository>().watchUnreadCount(
        uid: uid,
        isStaff: auth.profile?.role == UserRole.staff,
      ),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          child: icon,
        );
      },
    );
  }
}
