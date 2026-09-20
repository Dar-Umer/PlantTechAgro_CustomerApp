import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/orchard_theme.dart';
import '../../widgets/common.dart';
import '../order_detail_screen.dart';

const orderStatuses = [
  '',
  'pending',
  'assigned',
  'in_progress',
  'completed',
  'cancelled'
];

String _chipLabel(String s) =>
    s.isEmpty ? 'All' : s.replaceAll('_', ' ').toUpperCase();

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersState>().load(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text('Track Work Orders',
              style: Theme.of(context).textTheme.headlineMedium),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: orderStatuses.map((s) {
              final selected =
                  orders.statusFilter == (s.isEmpty ? null : s);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_chipLabel(s)),
                  selected: selected,
                  onSelected: (_) => orders.load(
                      status: s.isEmpty ? null : s, reset: true),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(child: _Body()),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersState>();
    if (orders.loading && orders.items.isEmpty) {
      return const LoadingView(message: 'Loading orders…');
    }
    if (orders.error != null && orders.items.isEmpty) {
      return ErrorView(
          message: orders.error!,
          onRetry: () => orders.load(reset: true));
    }
    if (orders.items.isEmpty) {
      return const EmptyView(
          message: 'No work orders yet. Book a service to get started.');
    }
    return RefreshIndicator(
      onRefresh: () => orders.load(reset: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: orders.items.length + (orders.hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= orders.items.length) {
            orders.load(reset: false);
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OrderCard(order: orders.items[i]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final WorkOrderSummary order;

  @override
  Widget build(BuildContext context) {
    final o = order;
    final timeline = [
      if (o.createdAt != null) ('Created', fmtDate(o.createdAt)),
      if (o.startedAt != null) ('Started', fmtDate(o.startedAt)),
      if (o.completedAt != null) ('Completed', fmtDate(o.completedAt)),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(o.number,
                      style:
                          Theme.of(context).textTheme.titleSmall),
                ),
                StatusChip(label: o.statusLabel, color: o.statusColor),
              ],
            ),
            const SizedBox(height: 2),
            Text(o.serviceName,
                style: const TextStyle(
                    fontSize: 13, color: OrchardColors.muted)),
            const SizedBox(height: 8),
            Text(
              'Stage: ${o.stagesCompleted} of ${o.stagesTotal} completed',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: o.progressPercent / 100,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text('${o.progressPercent}% complete',
                style: const TextStyle(
                    fontSize: 12, color: OrchardColors.muted)),
            if (timeline.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final (label, date) in timeline)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: OrchardColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$label • $date',
                          style: const TextStyle(
                              fontSize: 12,
                              color: OrchardColors.muted)),
                    ],
                  ),
                ),
            ],
            if (o.assignedTo != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: OrchardColors.muted),
                  const SizedBox(width: 4),
                  Text('Agent: ${o.assignedTo}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: OrchardColors.muted)),
                ],
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: OrchardColors.brand,
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(id: o.id)),
                ),
                child: const Text('View Step-By-Step Progress →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
