import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/orchard_theme.dart';
import '../../widgets/common.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsState>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotificationsState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unread > 0)
            TextButton(
              onPressed: () async {
                await state.markAllRead();
                if (context.mounted) showSnack(context, 'All marked as read.');
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: Builder(builder: (context) {
        if (state.loading && state.items.isEmpty) {
          return const LoadingView(message: 'Loading notifications…');
        }
        if (state.error != null && state.items.isEmpty) {
          return ErrorView(message: state.error!, onRetry: () => state.load());
        }
        if (state.items.isEmpty) {
          return const EmptyView(message: 'No notifications.');
        }
        return RefreshIndicator(
          onRefresh: () => state.load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.items.length,
            itemBuilder: (context, i) {
              final n = state.items[i];
              final rel = relativeTime(n.createdAt);
              return Card(
                color: n.isRead ? null : OrchardColors.tint50,
                child: ListTile(
                  leading: Stack(
                    children: [
                      Icon(
                        n.isRead
                            ? Icons.notifications_none
                            : Icons.notifications,
                        color: n.isRead
                            ? null
                            : OrchardColors.pine,
                      ),
                      if (!n.isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: OrchardColors.brand,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(n.title,
                      style: TextStyle(
                          fontWeight: n.isRead
                              ? FontWeight.normal
                              : FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (n.body.isNotEmpty) Text(n.body),
                      if (rel.isNotEmpty)
                        Text(rel,
                            style: const TextStyle(
                                fontSize: 12,
                                color: OrchardColors.muted)),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () => state.markRead(n),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
