import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/models/user_role.dart';
import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key, required this.incidentRoutePrefix});

  final String incidentRoutePrefix;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid;
    final isStaff = auth.profile?.role == UserRole.staff;
    if (uid == null) {
      return const LoadingView();
    }

    final repo = context.read<NotificationRepository>();

    return StreamBuilder<List<AppNotification>>(
      stream: repo.watchInbox(uid: uid, isStaff: isStaff),
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

        final hasUnread = items.any((n) => !n.isReadBy(uid));
        return Column(
          children: [
            if (hasUnread)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => repo.markAllRead(items, uid),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Mark all as read'),
                ),
              ),
            Expanded(child: _list(context, items, repo, uid)),
          ],
        );
      },
    );
  }

  Widget _list(
    BuildContext context,
    List<AppNotification> items,
    NotificationRepository repo,
    String uid,
  ) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final n = items[index];
        final read = n.isReadBy(uid);
        return ListTile(
          leading: Icon(
            read
                ? Icons.mark_email_read_outlined
                : Icons.mark_email_unread_outlined,
          ),
          title: Text(
            n.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: read ? null : const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${n.body}\n${DateFormat.yMMMd().add_jm().format(n.createdAt)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          onTap: () async {
            await repo.markRead(n, uid);
            if (n.incidentId.isNotEmpty) {
              context.push('$incidentRoutePrefix/${n.incidentId}');
            }
          },
        );
      },
    );
  }
}
