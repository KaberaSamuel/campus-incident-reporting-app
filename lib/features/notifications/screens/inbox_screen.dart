import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({
    super.key,
    required this.incidentRoutePrefix,
  });

  final String incidentRoutePrefix;

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;
    if (uid == null) {
      return const LoadingView();
    }

    final repo = context.read<NotificationRepository>();

    return StreamBuilder<List<AppNotification>>(
      stream: repo.watchForUser(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'Loading inbox…');
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const EmptyStateView(
            icon: Icons.inbox_outlined,
            title: 'Inbox empty',
            subtitle: 'Notifications about your reports will appear here.',
          );
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final n = items[index];
            return ListTile(
              leading: Icon(
                n.read ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
              ),
              title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${n.body}\n${DateFormat.yMMMd().add_jm().format(n.createdAt)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              onTap: () async {
                if (!n.read) {
                  await repo.markRead(n.id);
                }
                if (n.incidentId.isNotEmpty) {
                  context.push('$incidentRoutePrefix/${n.incidentId}');
                }
              },
            );
          },
        );
      },
    );
  }
}
